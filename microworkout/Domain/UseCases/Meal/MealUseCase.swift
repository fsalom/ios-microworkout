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
        await MainActor.run {
            NotificationCenter.default.post(name: .mealsChanged, object: nil)
        }
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
        await MainActor.run {
            NotificationCenter.default.post(name: .mealsChanged, object: nil)
        }
    }

    func fetchFoodByBarcode(_ barcode: String) async throws -> FoodItem? {
        // Primero intentamos la API remota; si no devuelve nada (o falla), miramos en
        // los alimentos personalizados que el usuario haya guardado offline.
        do {
            if let remote = try await repository.fetchFoodInfo(barcode: barcode) {
                return remote
            }
        } catch {
            print("[MealUseCase] remote barcode lookup failed: \(error)")
        }
        return getCustomFood(barcode: barcode)
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
        let sixtyDaysAgo: Date
        if let date = Calendar.current.date(byAdding: .day, value: -60, to: now) {
            sixtyDaysAgo = date
        } else {
            assertionFailure("Failed to compute date 60 days ago; falling back to now")
            sixtyDaysAgo = now
        }
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

    // MARK: - Favorites

    private func favoriteKey(for food: FoodItem) -> String {
        if let barcode = food.barcode, !barcode.isEmpty { return "barcode:\(barcode)" }
        return "name:\(food.name.lowercased())"
    }

    func getFavorites() -> [FoodItem] {
        repository.getFavorites()
    }

    func isFavorite(_ food: FoodItem) -> Bool {
        let key = favoriteKey(for: food)
        return getFavorites().contains { favoriteKey(for: $0) == key }
    }

    func toggleFavorite(_ food: FoodItem) {
        var favorites = repository.getFavorites()
        let key = favoriteKey(for: food)
        if let index = favorites.firstIndex(where: { favoriteKey(for: $0) == key }) {
            favorites.remove(at: index)
        } else {
            // Store a clean copy at quantity 100g (canonical) so future quick-adds use a
            // standard reference; the user adjusts via the picker anyway.
            var copy = food
            copy.quantity = 100
            favorites.insert(copy, at: 0)
        }
        repository.saveFavorites(favorites)
    }

    // MARK: - My meals

    func getMyMeals() -> [MyMeal] {
        repository.getMyMeals().sorted { $0.createdAt > $1.createdAt }
    }

    func saveMyMeal(_ myMeal: MyMeal) {
        var meals = repository.getMyMeals()
        if let index = meals.firstIndex(where: { $0.id == myMeal.id }) {
            meals[index] = myMeal
        } else {
            meals.insert(myMeal, at: 0)
        }
        repository.saveMyMeals(meals)
    }

    func deleteMyMeal(id: UUID) {
        var meals = repository.getMyMeals()
        meals.removeAll { $0.id == id }
        repository.saveMyMeals(meals)
    }

    // MARK: - Custom foods (offline fallback)

    func saveCustomFood(_ food: FoodItem) {
        guard let barcode = food.barcode, !barcode.isEmpty else { return }
        var dict = repository.getCustomFoods()
        var copy = food
        copy.quantity = 100
        dict[barcode] = copy
        repository.saveCustomFoods(dict)
    }

    func getCustomFood(barcode: String) -> FoodItem? {
        repository.getCustomFoods()[barcode]
    }
}
