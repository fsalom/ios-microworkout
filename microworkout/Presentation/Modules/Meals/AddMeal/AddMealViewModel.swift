//
//  AddMealViewModel.swift
//  microworkout
//

import Foundation
import SwiftUI

struct AddMealUiState {
    var selectedType: MealType = .breakfast
    var selectedTime: Date = Date()
    var items: [FoodItem] = []
    var isLoading: Bool = false
    var error: String?
    var showManualEntry: Bool = false

    // Manual entry fields
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

    init(router: AddMealRouter, mealUseCase: MealUseCaseProtocol) {
        self.router = router
        self.mealUseCase = mealUseCase
    }

    func selectMealType(_ type: MealType) {
        uiState.selectedType = type
    }

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

    func scanBarcode() {
        router.goToBarcodeScannerView { [weak self] foodItem in
            self?.addFoodItem(foodItem)
        }
    }

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
