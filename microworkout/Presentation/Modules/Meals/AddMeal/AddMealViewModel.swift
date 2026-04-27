//
//  AddMealViewModel.swift
//  microworkout
//

import Foundation
import SwiftUI
import Combine

enum AddMealListTab: String, CaseIterable, Identifiable {
    case recent = "Recientes"
    case favorites = "Favoritos"
    case myFoods = "Mis comidas"

    var id: String { rawValue }
}

struct AddMealUiState {
    var selectedType: MealType = .forCurrentTime()
    var selectedTime: Date = Date()
    var items: [FoodItem] = []
    var recentFoods: [FoodItem] = []
    var favoriteFoods: [FoodItem] = []
    var favoriteKeys: Set<String> = []
    var myMeals: [MyMeal] = []
    var selectedTab: AddMealListTab = .recent
    var recentlyAddedIds: Set<UUID> = []
    var isLoading: Bool = false
    var error: String?

    // Search state
    var searchQuery: String = ""
    var searchResults: [FoodItem] = []
    var isSearching: Bool = false

    // Manual entry
    var showManualEntry: Bool = false
    var manualName: String = ""
    var manualCalories: String = ""
    var manualCarbs: String = ""
    var manualProteins: String = ""
    var manualFats: String = ""
    var manualQuantity: String = "100"

    var totalNutrition: NutritionInfo {
        items.reduce(NutritionInfo.zero) { $0 + $1.actualNutrition }
    }

    var canSave: Bool {
        !items.isEmpty
    }

    var canAddManual: Bool {
        !manualName.isEmpty && !manualCalories.isEmpty
    }
}

final class AddMealViewModel: ObservableObject {
    @Published var uiState: AddMealUiState = .init()
    private var router: AddMealRouter
    private var mealUseCase: MealUseCaseProtocol
    private var searchTask: Task<Void, Never>?

    init(router: AddMealRouter, mealUseCase: MealUseCaseProtocol) {
        self.router = router
        self.mealUseCase = mealUseCase
        loadRecentFoods()
        loadFavorites()
        loadMyMeals()
    }

    func loadMyMeals() {
        uiState.myMeals = mealUseCase.getMyMeals()
    }

    func saveMyMeal(name: String, items: [FoodItem]) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !items.isEmpty else { return }
        let meal = MyMeal(name: trimmed, items: items)
        mealUseCase.saveMyMeal(meal)
        loadMyMeals()
    }

    func deleteMyMeal(id: UUID) {
        mealUseCase.deleteMyMeal(id: id)
        loadMyMeals()
    }

    /// Adds all items of a saved "Mi comida" as a single Meal of the current selectedType.
    func addMyMeal(_ myMeal: MyMeal) {
        let meal = Meal(
            type: uiState.selectedType,
            timestamp: Date(),
            items: myMeal.items
        )

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        Task {
            do {
                try await mealUseCase.saveMeal(meal)
                await MainActor.run { self.loadRecentFoods() }
            } catch {
                await MainActor.run { self.uiState.error = "Error al guardar" }
            }
        }
    }

    func loadFavorites() {
        let favs = mealUseCase.getFavorites()
        uiState.favoriteFoods = favs
        uiState.favoriteKeys = Set(favs.map { favoriteKey(for: $0) })
    }

    func toggleFavorite(_ food: FoodItem) {
        mealUseCase.toggleFavorite(food)
        loadFavorites()
    }

    func isFavorite(_ food: FoodItem) -> Bool {
        uiState.favoriteKeys.contains(favoriteKey(for: food))
    }

    private func favoriteKey(for food: FoodItem) -> String {
        if let barcode = food.barcode, !barcode.isEmpty { return "barcode:\(barcode)" }
        return "name:\(food.name.lowercased())"
    }

    /// Prepends favorites that match the query to the search results.
    /// Avoids duplicates by removing the same food from `results` if also in favorites.
    private func prependMatchingFavorites(to results: [FoodItem], query: String) -> [FoodItem] {
        let normalized = query.lowercased()
        let matchingFavorites = uiState.favoriteFoods.filter { fav in
            fav.name.lowercased().contains(normalized)
        }
        guard !matchingFavorites.isEmpty else { return results }

        let favKeys = Set(matchingFavorites.map { favoriteKey(for: $0) })
        let withoutDuplicates = results.filter { !favKeys.contains(favoriteKey(for: $0)) }
        return matchingFavorites + withoutDuplicates
    }

    func selectMealType(_ type: MealType) {
        uiState.selectedType = type
    }

    func selectTab(_ tab: AddMealListTab) {
        uiState.selectedTab = tab
    }

    /// Saves a single-item meal of the current selectedType with the given food.
    /// Used by the quick "+" buttons in the food list. Tracks `recentlyAddedIds`
    /// so the row can show feedback and prevent double-taps.
    func quickAdd(_ food: FoodItem) {
        guard !uiState.recentlyAddedIds.contains(food.id) else { return }
        uiState.recentlyAddedIds.insert(food.id)

        let item = FoodItem(
            name: food.name,
            barcode: food.barcode,
            nutritionPer100g: food.nutritionPer100g,
            quantity: food.quantity,
            servingSize: food.servingSize,
            imageUrl: food.imageUrl
        )
        let meal = Meal(
            type: uiState.selectedType,
            timestamp: Date(),
            items: [item]
        )

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        Task {
            do {
                try await mealUseCase.saveMeal(meal)
                await MainActor.run {
                    self.loadRecentFoods()
                }
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s feedback
                await MainActor.run {
                    self.uiState.recentlyAddedIds.remove(food.id)
                }
            } catch {
                await MainActor.run {
                    self.uiState.error = "Error al guardar"
                    self.uiState.recentlyAddedIds.remove(food.id)
                }
            }
        }
    }

    // MARK: - Search

    func searchFoods() {
        let query = uiState.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            uiState.searchResults = []
            uiState.isSearching = false
            return
        }

        // Cancel previous search
        searchTask?.cancel()

        uiState.isSearching = true

        searchTask = Task {
            // Small additional coalescing window; the SearchField already debounces 200ms.
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

            guard !Task.isCancelled else { return }

            do {
                let results = try await mealUseCase.searchFoods(query: query)
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    // Stale guard: if the user has already typed a different query while
                    // this request was in flight, ignore this response so it doesn't
                    // overwrite the newer state.
                    guard self.uiState.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) == query else { return }
                    self.uiState.searchResults = self.prependMatchingFavorites(to: results, query: query)
                    self.uiState.isSearching = false
                }
            } catch is CancellationError {
                return
            } catch let urlError as URLError where urlError.code == .cancelled {
                return
            } catch {
                print("[AddMeal] searchFoods error: \(error)")
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    guard self.uiState.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) == query else { return }
                    self.uiState.searchResults = []
                    self.uiState.isSearching = false
                    self.uiState.error = "Error de búsqueda"
                }
            }
        }
    }

    func clearSearch() {
        uiState.searchQuery = ""
        uiState.searchResults = []
        searchTask?.cancel()
    }

    func selectSearchResult(_ item: FoodItem) {
        addFoodItem(item)
        clearSearch()
    }

    // MARK: - Recent Foods

    func loadRecentFoods() {
        Task {
            do {
                let foods = try await mealUseCase.getRecentFoods(limit: 10)
                await MainActor.run {
                    self.uiState.recentFoods = foods
                }
            } catch {
                // Silently fail — recent foods are not critical
            }
        }
    }

    func addRecentFood(_ food: FoodItem) {
        let newItem = FoodItem(
            name: food.name,
            barcode: food.barcode,
            nutritionPer100g: food.nutritionPer100g,
            quantity: food.quantity,
            servingSize: food.servingSize,
            imageUrl: food.imageUrl
        )
        addFoodItem(newItem)
    }

    // MARK: - Food Items

    func addFoodItem(_ item: FoodItem) {
        uiState.items.append(item)
    }

    func updateFoodItem(at index: Int, with item: FoodItem) {
        guard index < uiState.items.count else { return }
        uiState.items[index] = item
    }

    func removeFoodItem(at index: Int) {
        guard index < uiState.items.count else { return }
        uiState.items.remove(at: index)
    }

    // MARK: - Manual Entry

    func toggleManualEntry() {
        uiState.showManualEntry.toggle()
        if !uiState.showManualEntry {
            clearManualFields()
        }
    }

    func addManualFood() {
        guard uiState.canAddManual else { return }

        let nutrition = NutritionInfo(
            calories: Double(uiState.manualCalories) ?? 0,
            carbohydrates: Double(uiState.manualCarbs) ?? 0,
            proteins: Double(uiState.manualProteins) ?? 0,
            fats: Double(uiState.manualFats) ?? 0
        )

        let quantity = Double(uiState.manualQuantity) ?? 100

        let item = FoodItem(
            name: uiState.manualName,
            nutritionPer100g: nutrition.scaled(by: 100 / quantity),
            quantity: quantity
        )

        addFoodItem(item)
        clearManualFields()
        uiState.showManualEntry = false
    }

    private func clearManualFields() {
        uiState.manualName = ""
        uiState.manualCalories = ""
        uiState.manualCarbs = ""
        uiState.manualProteins = ""
        uiState.manualFats = ""
        uiState.manualQuantity = "100"
    }

    // MARK: - Barcode

    func scanBarcode() {
        router.goToBarcodeScannerView { [weak self] foodItem in
            self?.addFoodItem(foodItem)
        }
    }

    // MARK: - Save

    func saveMeal() {
        guard uiState.canSave else { return }

        uiState.isLoading = true

        let meal = Meal(
            type: uiState.selectedType,
            timestamp: uiState.selectedTime,
            items: uiState.items
        )

        Task {
            do {
                try await mealUseCase.saveMeal(meal)
                await MainActor.run {
                    self.uiState.isLoading = false
                    self.router.goBack()
                }
            } catch {
                await MainActor.run {
                    self.uiState.error = "Error al guardar la comida"
                    self.uiState.isLoading = false
                }
            }
        }
    }

    func goBack() {
        router.goBack()
    }
}
