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

    func searchFoods(query: String) async throws -> [FoodItem] {
        try await repository.searchFoods(query: query)
    }

    func getTodayTotals() async throws -> NutritionInfo {
        let meals = try await getMealsForToday()
        return meals.reduce(NutritionInfo.zero) { $0 + $1.totalNutrition }
    }

    func getRecentFoods(limit: Int) async throws -> [FoodItem] {
        let now = Date()
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: now)!
        let meals = try await repository.getMeals(from: sixtyDaysAgo, to: now)

        // Extract all food items sorted by meal timestamp (most recent first)
        let sortedMeals = meals.sorted { $0.timestamp > $1.timestamp }
        var seen = Set<String>()
        var recentFoods: [FoodItem] = []

        for meal in sortedMeals {
            for item in meal.items {
                let key = item.name.lowercased()
                if !seen.contains(key) {
                    seen.insert(key)
                    recentFoods.append(item)
                    if recentFoods.count >= limit {
                        return recentFoods
                    }
                }
            }
        }

        return recentFoods
    }
}
