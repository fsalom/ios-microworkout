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

    /// Meals from yesterday matching the currently selected `selectedType`. Used to
    /// surface "repetir comida de ayer" suggestions. Refreshed when `selectedType` changes.
    var previousDayMeals: [Meal] = []
    /// Ids of meals from yesterday that were just re-saved today, for transient UI feedback.
    var repeatedMealIds: Set<UUID> = []

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
    /// Bumped on every search invocation; the in-flight task only resets `isSearching`
    /// if its captured generation matches the current one. Prevents stuck spinners
    /// when a task is cancelled by a follow-up search.
    private var searchGeneration: Int = 0

    init(router: AddMealRouter, mealUseCase: MealUseCaseProtocol) {
        self.router = router
        self.mealUseCase = mealUseCase
        loadRecentFoods()
        loadFavorites()
        loadMyMeals()
        loadPreviousDayMeals()
    }

    /// Fetches yesterday's meals that match the currently selected meal type.
    /// Filtering by `selectedType` is what makes the suggestion contextual ("en cada caso"):
    /// when adding breakfast, only yesterday's breakfast is shown.
    func loadPreviousDayMeals() {
        let type = uiState.selectedType
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        Task {
            do {
                let meals = try await mealUseCase.getMeals(for: yesterday)
                let filtered = meals
                    .filter { $0.type == type && !$0.items.isEmpty }
                    .sorted { $0.timestamp < $1.timestamp }
                await MainActor.run {
                    self.uiState.previousDayMeals = filtered
                }
            } catch {
                await MainActor.run { self.uiState.previousDayMeals = [] }
            }
        }
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

    /// Saves or updates a MyMeal using its existing id (upsert behaviour).
    func saveMyMeal(_ meal: MyMeal) {
        let trimmed = meal.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !meal.items.isEmpty else { return }
        var copy = meal
        copy.name = trimmed
        mealUseCase.saveMyMeal(copy)
        loadMyMeals()
    }

    func deleteMyMeal(id: UUID) {
        mealUseCase.deleteMyMeal(id: id)
        loadMyMeals()
    }

    /// Re-saves yesterday's meal as a fresh Meal today: same items, same meal type,
    /// new id and `timestamp = Date()`. One tap = "volver a poner lo mismo".
    func repeatMeal(_ source: Meal) {
        guard !uiState.repeatedMealIds.contains(source.id) else { return }
        uiState.repeatedMealIds.insert(source.id)

        let meal = Meal(
            type: uiState.selectedType,
            timestamp: Date(),
            items: source.items,
            myMealName: source.myMealName
        )

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        Task {
            do {
                try await mealUseCase.saveMeal(meal)
                await MainActor.run { self.loadRecentFoods() }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run { self.uiState.repeatedMealIds.remove(source.id) }
            } catch {
                await MainActor.run {
                    self.uiState.error = "Error al guardar"
                    self.uiState.repeatedMealIds.remove(source.id)
                }
            }
        }
    }

    /// Adds all items of a saved "Mi comida" as a single Meal of the current selectedType.
    func addMyMeal(_ myMeal: MyMeal) {
        let meal = Meal(
            type: uiState.selectedType,
            timestamp: Date(),
            items: myMeal.items,
            myMealName: myMeal.name
        )
        print("[AddMeal] addMyMeal name=\(myMeal.name) items=\(myMeal.items.count) type=\(uiState.selectedType)")

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        Task {
            do {
                try await mealUseCase.saveMeal(meal)
                print("[AddMeal] addMyMeal saved meal id=\(meal.id)")
                await MainActor.run { self.loadRecentFoods() }
            } catch {
                print("[AddMeal] addMyMeal save error: \(error)")
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
        guard uiState.selectedType != type else { return }
        uiState.selectedType = type
        loadPreviousDayMeals()
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
            searchTask?.cancel()
            searchTask = nil
            searchGeneration += 1
            uiState.searchResults = []
            uiState.isSearching = false
            return
        }

        searchTask?.cancel()
        searchGeneration += 1
        let generation = searchGeneration

        uiState.isSearching = true

        searchTask = Task { [weak self] in
            // Small additional coalescing window; the SearchField already debounces 200ms.
            try? await Task.sleep(nanoseconds: 100_000_000)

            // Whatever happens below (success, error, cancellation), guarantee the
            // spinner is reset if this task is still the latest one. Without this,
            // a cancelled task leaves `isSearching = true` forever.
            defer {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    guard self.searchGeneration == generation else { return }
                    self.uiState.isSearching = false
                }
            }

            guard !Task.isCancelled else { return }
            guard let self else { return }

            do {
                let results = try await self.mealUseCase.searchFoods(query: query)
                try Task.checkCancellation()
                await MainActor.run {
                    guard self.searchGeneration == generation else { return }
                    self.uiState.searchResults = self.prependMatchingFavorites(to: results, query: query)
                }
            } catch is CancellationError {
                return
            } catch let urlError as URLError where urlError.code == .cancelled {
                return
            } catch {
                print("[AddMeal] searchFoods error: \(error)")
                await MainActor.run {
                    guard self.searchGeneration == generation else { return }
                    self.uiState.searchResults = []
                    self.uiState.error = "Error de búsqueda"
                }
            }
        }
    }

    func clearSearch() {
        searchTask?.cancel()
        searchTask = nil
        searchGeneration += 1
        uiState.searchQuery = ""
        uiState.searchResults = []
        uiState.isSearching = false
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
