//
//  AddMealViewModel.swift
//  microworkout
//

import Foundation
import SwiftUI
import Combine

struct AddMealUiState {
    var selectedType: MealType = .forCurrentTime()
    var selectedTime: Date = Date()
    var items: [FoodItem] = []
    var recentFoods: [FoodItem] = []
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
    }

    func selectMealType(_ type: MealType) {
        uiState.selectedType = type
    }

    // MARK: - Search

    func searchFoods() {
        let query = uiState.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            uiState.searchResults = []
            return
        }

        // Cancel previous search
        searchTask?.cancel()

        uiState.isSearching = true

        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

            guard !Task.isCancelled else { return }

            do {
                let results = try await mealUseCase.searchFoods(query: query)
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    self.uiState.searchResults = results
                    self.uiState.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.uiState.searchResults = []
                    self.uiState.isSearching = false
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
