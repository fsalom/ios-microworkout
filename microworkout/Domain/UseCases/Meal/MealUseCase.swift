//
//  MealUseCase.swift
//  microworkout
//

import Foundation

/// Implementación de los casos de uso para gestionar comidas.
class MealUseCase: MealUseCaseProtocol {
    private let repository: MealRepositoryProtocol

    init(repository: MealRepositoryProtocol) {
        self.repository = repository
    }

    func saveMeal(_ meal: Meal) async throws {
        try await repository.saveMeal(meal)
    }

    func getMealsForToday() async throws -> [Meal] {
        let today = Calendar.current.startOfDay(for: Date())
        return try await repository.getMeals(for: today)
    }

    func getMeals(for date: Date) async throws -> [Meal] {
        try await repository.getMeals(for: date)
    }

    func deleteMeal(_ mealId: UUID) async throws {
        try await repository.deleteMeal(mealId)
    }

    func fetchFoodByBarcode(_ barcode: String) async throws -> FoodItem? {
        try await repository.fetchFoodInfo(barcode: barcode)
    }

    func getTodayTotals() async throws -> NutritionInfo {
        let meals = try await getMealsForToday()
        return meals.reduce(NutritionInfo.zero) { $0 + $1.totalNutrition }
    }
}
