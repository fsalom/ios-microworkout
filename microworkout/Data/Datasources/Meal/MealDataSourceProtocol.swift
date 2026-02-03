//
//  MealDataSourceProtocol.swift
//  microworkout
//

import Foundation

/// Protocolo para acceder a la fuente de datos local de comidas.
public protocol MealDataSourceProtocol {
    /// Guarda una comida.
    func saveMeal(_ meal: Meal) async throws

    /// Recupera todas las comidas.
    func getAllMeals() async throws -> [Meal]

    /// Recupera las comidas de una fecha específica.
    func getMeals(for date: Date) async throws -> [Meal]

    /// Recupera las comidas en un rango de fechas.
    func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal]

    /// Elimina una comida por su identificador.
    func deleteMeal(_ mealId: UUID) async throws
}
