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
}
