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

    /// Calcula los totales nutricionales del día actual.
    func getTodayTotals() async throws -> NutritionInfo
}
