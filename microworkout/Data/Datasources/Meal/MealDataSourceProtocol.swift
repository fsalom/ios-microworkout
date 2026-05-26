import Foundation

/// Protocolo de la fuente de datos local de comidas.
///
/// Opera con DTOs (`MealDTO`, `FoodItemDTO`, `MyMealDTO`) en lugar de entidades
/// de Domain. Esto desacopla el formato on-disk de cualquier rename o cambio
/// estructural en las entidades — la conversión Entity↔DTO la hace el repo.
protocol MealDataSourceProtocol {
    // MARK: Meals
    func saveMeal(_ meal: MealDTO) async throws
    func getAllMeals() async throws -> [MealDTO]
    func getMeals(for date: Date) async throws -> [MealDTO]
    func getMeals(from startDate: Date, to endDate: Date) async throws -> [MealDTO]
    func deleteMeal(_ mealId: UUID) async throws

    // MARK: Favorites
    func getFavorites() -> [FoodItemDTO]
    func saveFavorites(_ favorites: [FoodItemDTO])

    // MARK: My meals (recipes)
    func getMyMeals() -> [MyMealDTO]
    func saveMyMeals(_ meals: [MyMealDTO])

    // MARK: Custom foods (offline fallback for unknown barcodes)
    func getCustomFoods() -> [String: FoodItemDTO]
    func saveCustomFoods(_ foods: [String: FoodItemDTO])
}
