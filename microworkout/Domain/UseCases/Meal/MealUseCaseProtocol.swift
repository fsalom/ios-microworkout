//
//  MealUseCaseProtocol.swift
//  microworkout
//

import Foundation

/// Casos de uso para gestionar comidas.
protocol MealUseCaseProtocol {
    /// Guarda una comida.
    func saveMeal(_ meal: Meal) async throws

    /// Recupera las comidas del día actual.
    func getMealsForToday() async throws -> [Meal]

    /// Recupera las comidas de una fecha específica.
    func getMeals(for date: Date) async throws -> [Meal]

    /// Elimina una comida por su identificador.
    func deleteMeal(_ mealId: UUID) async throws

    /// Busca información de un alimento por código de barras.
    func fetchFoodByBarcode(_ barcode: String) async throws -> FoodItem?

    /// Busca alimentos por texto.
    func searchFoods(query: String) async throws -> [FoodItem]

    /// Calcula los totales nutricionales del día actual.
    func getTodayTotals() async throws -> NutritionInfo

    /// Devuelve los alimentos usados recientemente, deduplicados por nombre.
    func getRecentFoods(limit: Int) async throws -> [FoodItem]

    // MARK: Favorites

    /// Devuelve la lista de alimentos marcados como favoritos.
    func getFavorites() -> [FoodItem]

    /// Indica si un alimento está marcado como favorito.
    func isFavorite(_ food: FoodItem) -> Bool

    /// Alterna el estado de favorito del alimento.
    func toggleFavorite(_ food: FoodItem)

    // MARK: My meals (recipes)

    /// Devuelve la lista de "Mis comidas" guardadas (recetas).
    func getMyMeals() -> [MyMeal]

    /// Guarda o actualiza una receta personalizada.
    func saveMyMeal(_ myMeal: MyMeal)

    /// Elimina una receta por id.
    func deleteMyMeal(id: UUID)

    // MARK: Custom foods (offline fallback for unknown barcodes)

    /// Guarda un FoodItem creado por el usuario, identificable por su `barcode`.
    func saveCustomFood(_ food: FoodItem)

    /// Recupera un FoodItem creado por el usuario por su `barcode`.
    func getCustomFood(barcode: String) -> FoodItem?
}
