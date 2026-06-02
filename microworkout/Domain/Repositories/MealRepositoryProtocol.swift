//
//  MealRepositoryProtocol.swift
//  microworkout
//

import Foundation

/// Protocolo para acceder al repositorio de comidas.
/// Todos los métodos son `async throws`: el reparto local/remoto por estado
/// de auth lo hace el repositorio en cada llamada.
protocol MealRepositoryProtocol {
    func saveMeal(_ meal: Meal) async throws
    func getMeals(for date: Date) async throws -> [Meal]
    func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal]
    func deleteMeal(_ mealId: UUID) async throws
    func fetchFoodInfo(barcode: String) async throws -> FoodItem?
    func searchFoods(query: String) async throws -> [FoodItem]

    // MARK: Favorites
    func getFavorites() async throws -> [FoodItem]
    func saveFavorites(_ favorites: [FoodItem]) async throws

    // MARK: My meals (recipes)
    func getMyMeals() async throws -> [MyMeal]
    func saveMyMeals(_ meals: [MyMeal]) async throws

    // MARK: Custom foods (offline fallback for unknown barcodes — always local)
    func getCustomFoods() -> [String: FoodItem]
    func saveCustomFoods(_ foods: [String: FoodItem])
}
