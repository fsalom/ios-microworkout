import Foundation

/// Convierte Domain ↔ DTO en la frontera con el datasource local. La capa
/// Domain nunca ve el formato on-disk; cualquier cambio de naming en las
/// entidades es absorbido aquí sin tocar datos persistidos.
class MealRepository: MealRepositoryProtocol {
    private let localDataSource: MealDataSourceProtocol
    private let remoteApi: OpenFoodFactsApiProtocol

    init(localDataSource: MealDataSourceProtocol, remoteApi: OpenFoodFactsApiProtocol) {
        self.localDataSource = localDataSource
        self.remoteApi = remoteApi
    }

    // MARK: Meals

    func saveMeal(_ meal: Meal) async throws {
        try await localDataSource.saveMeal(meal.toDTO())
    }

    func getMeals(for date: Date) async throws -> [Meal] {
        try await localDataSource.getMeals(for: date).map { $0.toDomain() }
    }

    func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] {
        try await localDataSource.getMeals(from: startDate, to: endDate).map { $0.toDomain() }
    }

    func deleteMeal(_ mealId: UUID) async throws {
        try await localDataSource.deleteMeal(mealId)
    }

    // MARK: Remote (OpenFoodFacts)

    func fetchFoodInfo(barcode: String) async throws -> FoodItem? {
        do {
            guard let productDTO = try await remoteApi.fetchProduct(barcode: barcode) else {
                return nil
            }
            return productDTO.toDomain(barcode: barcode)
        } catch {
            throw DomainError.map(error)
        }
    }

    func searchFoods(query: String) async throws -> [FoodItem] {
        do {
            let products = try await remoteApi.searchProducts(query: query, page: 1, pageSize: 25)
            return products.map { $0.toDomain() }
        } catch {
            throw DomainError.map(error)
        }
    }

    // MARK: Favorites

    func getFavorites() -> [FoodItem] {
        localDataSource.getFavorites().map { $0.toDomain() }
    }

    func saveFavorites(_ favorites: [FoodItem]) {
        localDataSource.saveFavorites(favorites.map { $0.toDTO() })
    }

    // MARK: My meals

    func getMyMeals() -> [MyMeal] {
        localDataSource.getMyMeals().map { $0.toDomain() }
    }

    func saveMyMeals(_ meals: [MyMeal]) {
        localDataSource.saveMyMeals(meals.map { $0.toDTO() })
    }

    // MARK: Custom foods

    func getCustomFoods() -> [String: FoodItem] {
        localDataSource.getCustomFoods().mapValues { $0.toDomain() }
    }

    func saveCustomFoods(_ foods: [String: FoodItem]) {
        localDataSource.saveCustomFoods(foods.mapValues { $0.toDTO() })
    }
}

fileprivate extension OpenFoodFactsProductDTO {
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
