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
    var isLoading: Bool = false
    var error: String?

    var mealsByType: [MealType: [Meal]] {
        Dictionary(grouping: todayMeals, by: { $0.type })
    }
}

final class MealsViewModel: ObservableObject {
    @Published var uiState: MealsUiState = .init()
    private var router: MealsRouter
    private var mealUseCase: MealUseCaseProtocol

    init(router: MealsRouter, mealUseCase: MealUseCaseProtocol) {
        self.router = router
        self.mealUseCase = mealUseCase
        loadMeals()
    }

    func loadMeals() {
        uiState.isLoading = true
        Task {
            do {
                let meals = try await mealUseCase.getMeals(for: uiState.selectedDate)
                let totals = meals.reduce(NutritionInfo.zero) { $0 + $1.totalNutrition }
                await MainActor.run {
                    self.uiState.todayMeals = meals.sorted { $0.timestamp < $1.timestamp }
                    self.uiState.todayTotals = totals
                    self.uiState.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.uiState.error = "Error al cargar las comidas"
                    self.uiState.isLoading = false
                }
            }
        }
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

    func changeDate(to date: Date) {
        uiState.selectedDate = date
        loadMeals()
    }

    func goToAddMeal() {
        router.goToAddMeal()
    }
}
