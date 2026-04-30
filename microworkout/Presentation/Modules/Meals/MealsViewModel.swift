//
//  MealsViewModel.swift
//  microworkout
//

import Foundation
import SwiftUI

struct MealsUiState {
    var todayMeals: [Meal] = []
    var todayTotals: NutritionInfo = .zero
    var selectedDate: Date = .init()
    var dailyCalorieTarget: Double? = nil
    var macroTargets: NutritionInfo? = nil
    var isLoading: Bool = false
    var error: String?

    var mealsByType: [MealType: [Meal]] {
        Dictionary(grouping: todayMeals, by: { $0.type })
    }

    var caloriesRemaining: Double {
        guard let target = dailyCalorieTarget else { return 0 }
        return target - todayTotals.calories
    }

    var calorieProgress: Double {
        guard let target = dailyCalorieTarget, target > 0 else { return 0 }
        return min(todayTotals.calories / target, 1.0)
    }
}

final class MealsViewModel: ObservableObject {
    @Published var uiState: MealsUiState = .init()
    private var router: MealsRouter
    private var mealUseCase: MealUseCaseProtocol
    private var userProfileUseCase: UserProfileUseCaseProtocol

    init(router: MealsRouter,
         mealUseCase: MealUseCaseProtocol,
         userProfileUseCase: UserProfileUseCaseProtocol) {
        self.router = router
        self.mealUseCase = mealUseCase
        self.userProfileUseCase = userProfileUseCase
        loadProfileTargets()
        loadMeals()
    }

    func loadMeals() {
        uiState.isLoading = true
        Task {
            do {
                let meals = try await mealUseCase.getMeals(for: uiState.selectedDate)
                let totals = meals.reduce(NutritionInfo.zero) { $0 + $1.totalNutrition }
                let recipeCount = meals.filter { $0.myMealName != nil }.count
                print("[Meals] loadMeals fetched \(meals.count) total, \(recipeCount) recipe(s) for \(uiState.selectedDate)")
                await MainActor.run {
                    self.uiState.todayMeals = meals.sorted { $0.timestamp < $1.timestamp }
                    self.uiState.todayTotals = totals
                    self.uiState.isLoading = false
                }
            } catch {
                print("[Meals] loadMeals error: \(error)")
                await MainActor.run {
                    self.uiState.error = "Error al cargar las comidas"
                    self.uiState.isLoading = false
                }
            }
        }
    }

    private func loadProfileTargets() {
        let profile = userProfileUseCase.getProfile()
        uiState.dailyCalorieTarget = profile?.todayCalorieTarget
        uiState.macroTargets = profile?.todayMacroTargets
    }

    func deleteMeal(id: UUID) {
        Task {
            do {
                try await mealUseCase.deleteMeal(id)
                await MainActor.run {
                    self.loadMeals()
                }
            } catch {
                await MainActor.run {
                    self.uiState.error = "Error al eliminar la comida"
                }
            }
        }
    }

    /// Replaces the quantity of a single food item in a meal. Re-saves the meal
    /// (delete + save workaround since there is no `updateMeal` API).
    func updateFoodItem(itemId: UUID, mealId: UUID, newQuantity: Double) {
        guard let meal = uiState.todayMeals.first(where: { $0.id == mealId }) else { return }
        guard newQuantity > 0 else { return }

        let updatedItems: [FoodItem] = meal.items.map { item in
            guard item.id == itemId else { return item }
            var copy = item
            copy.quantity = newQuantity
            return copy
        }

        let updatedMeal = Meal(
            id: meal.id,
            type: meal.type,
            timestamp: meal.timestamp,
            items: updatedItems
        )

        Task {
            do {
                try await mealUseCase.deleteMeal(meal.id)
                try await mealUseCase.saveMeal(updatedMeal)
                await MainActor.run { self.loadMeals() }
            } catch {
                await MainActor.run { self.uiState.error = "Error al actualizar" }
            }
        }
    }

    /// Deletes a single food item from a meal. If the meal had only that item,
    /// the entire meal is removed. Otherwise the meal is updated removing the item.
    func deleteFoodItem(itemId: UUID, mealId: UUID) {
        print("[Meals] deleteFoodItem called itemId=\(itemId) mealId=\(mealId)")
        guard let meal = uiState.todayMeals.first(where: { $0.id == mealId }) else {
            print("[Meals] meal not found in todayMeals")
            return
        }
        print("[Meals] meal items count=\(meal.items.count)")

        Task {
            do {
                try await mealUseCase.deleteMeal(mealId)
                print("[Meals] meal deleted")
                if meal.items.count > 1 {
                    let remaining = meal.items.filter { $0.id != itemId }
                    let updated = Meal(
                        id: meal.id,
                        type: meal.type,
                        timestamp: meal.timestamp,
                        items: remaining
                    )
                    try await mealUseCase.saveMeal(updated)
                    print("[Meals] re-saved meal with \(remaining.count) items")
                }
                await MainActor.run {
                    self.loadMeals()
                }
            } catch {
                print("[Meals] delete error: \(error)")
                await MainActor.run {
                    self.uiState.error = "Error al eliminar"
                }
            }
        }
    }

    func changeDate(to date: Date) {
        uiState.selectedDate = date
        loadProfileTargets()
        loadMeals()
    }

    func goToPreviousDay() {
        let prev = Calendar.current.date(byAdding: .day, value: -1, to: uiState.selectedDate) ?? uiState.selectedDate
        changeDate(to: prev)
    }

    func goToNextDay() {
        let next = Calendar.current.date(byAdding: .day, value: 1, to: uiState.selectedDate) ?? uiState.selectedDate
        changeDate(to: next)
    }

    var canGoToNextDay: Bool {
        let cal = Calendar.current
        return !cal.isDateInToday(uiState.selectedDate) && uiState.selectedDate < Date()
    }

    func goToAddMeal() {
        router.goToAddMeal(prefilledType: nil)
    }

    func goToAddMeal(for type: MealType) {
        router.goToAddMeal(prefilledType: type)
    }

    func goToBarcodeScanner() {
        router.goToBarcodeScanner()
    }
}
