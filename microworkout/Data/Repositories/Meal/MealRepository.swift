//
//  MealRepository.swift
//  microworkout
//

import Foundation

/// Implementación del repositorio de comidas.
class MealRepository: MealRepositoryProtocol {
    private let localDataSource: MealDataSourceProtocol
    private let remoteApi: OpenFoodFactsApiProtocol

    init(localDataSource: MealDataSourceProtocol, remoteApi: OpenFoodFactsApiProtocol) {
        self.localDataSource = localDataSource
        self.remoteApi = remoteApi
    }

    func saveMeal(_ meal: Meal) async throws {
        try await localDataSource.saveMeal(meal)
    }

    func getMeals(for date: Date) async throws -> [Meal] {
        try await localDataSource.getMeals(for: date)
    }

    func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] {
        try await localDataSource.getMeals(from: startDate, to: endDate)
    }

    func deleteMeal(_ mealId: UUID) async throws {
        try await localDataSource.deleteMeal(mealId)
    }

    func fetchFoodInfo(barcode: String) async throws -> FoodItem? {
        guard let productDTO = try await remoteApi.fetchProduct(barcode: barcode) else {
            return nil
        }
        return productDTO.toDomain(barcode: barcode)
    }

    func searchFoods(query: String) async throws -> [FoodItem] {
        let products = try await remoteApi.searchProducts(query: query, page: 1, pageSize: 25)
        return products.map { $0.toDomain() }
    }

    // MARK: Favorites

    func getFavorites() -> [FoodItem] {
        localDataSource.getFavorites()
    }

    func saveFavorites(_ favorites: [FoodItem]) {
        localDataSource.saveFavorites(favorites)
    }

    // MARK: My meals

    func getMyMeals() -> [MyMeal] {
        localDataSource.getMyMeals()
    }

    func saveMyMeals(_ meals: [MyMeal]) {
        localDataSource.saveMyMeals(meals)
    }

    // MARK: Custom foods

    func getCustomFoods() -> [String: FoodItem] {
        localDataSource.getCustomFoods()
    }

    func saveCustomFoods(_ foods: [String: FoodItem]) {
        localDataSource.saveCustomFoods(foods)
    }
}

fileprivate extension OpenFoodFactsProductDTO {
    /// Convierte el DTO a entidad de dominio FoodItem.
    func toDomain(barcode: String? = nil) -> FoodItem {
        FoodItem(
            id: UUID(),
            name: displayName,
            barcode: barcode ?? code,
            nutritionPer100g: NutritionInfo(
                calories: nutriments?.energyKcal100g ?? 0,
                carbohydrates: nutriments?.carbohydrates100g ?? 0,
                proteins: nutriments?.proteins100g ?? 0,
                fats: nutriments?.fat100g ?? 0,
                fiber: nutriments?.fiber100g
            ),
            quantity: 100,
            servingSize: nil,
            imageUrl: thumbnailUrl ?? imageUrl
        )
    }
}
