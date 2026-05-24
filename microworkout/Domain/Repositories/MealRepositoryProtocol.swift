//
//  MealRepositoryProtocol.swift
//  microworkout
//

import Foundation

/// Protocolo para acceder al repositorio de comidas.
protocol MealRepositoryProtocol {
    func saveMeal(_ meal: Meal) async throws
    func getMeals(for date: Date) async throws -> [Meal]
    func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal]
    func deleteMeal(_ mealId: UUID) async throws
    func fetchFoodInfo(barcode: String) async throws -> FoodItem?
    func searchFoods(query: String) async throws -> [FoodItem]

    // MARK: Favorites
    func getFavorites() -> [FoodItem]
    func saveFavorites(_ favorites: [FoodItem])

    // MARK: My meals (recipes)
    func getMyMeals() -> [MyMeal]
    func saveMyMeals(_ meals: [MyMeal])

    // MARK: Custom foods (offline fallback for unknown barcodes)
    func getCustomFoods() -> [String: FoodItem]
    func saveCustomFoods(_ foods: [String: FoodItem])
}
