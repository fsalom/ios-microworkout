//
//  MealLocalDataSource.swift
//  microworkout
//

import Foundation

/// Persistencia de Meal usando UserDefaults.
class MealLocalDataSource: MealDataSourceProtocol {
    private let storage: UserDefaultsManagerProtocol

    private enum Keys: String {
        case meals
    }

    init(storage: UserDefaultsManagerProtocol = UserDefaultsManager()) {
        self.storage = storage
    }

    func saveMeal(_ meal: Meal) async throws {
        var all: [Meal] = storage.get(forKey: Keys.meals.rawValue) ?? []
        if let idx = all.firstIndex(where: { $0.id == meal.id }) {
            all[idx] = meal
        } else {
            all.append(meal)
        }
        storage.save(all, forKey: Keys.meals.rawValue)
    }

    func getAllMeals() async throws -> [Meal] {
        storage.get(forKey: Keys.meals.rawValue) ?? []
    }

    func getMeals(for date: Date) async throws -> [Meal] {
        let all: [Meal] = storage.get(forKey: Keys.meals.rawValue) ?? []
        let calendar = Calendar.current
        return all.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }

    func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] {
        let all: [Meal] = storage.get(forKey: Keys.meals.rawValue) ?? []
        return all.filter { meal in
            meal.timestamp >= startDate && meal.timestamp <= endDate
        }
    }

    func deleteMeal(_ mealId: UUID) async throws {
        var all: [Meal] = storage.get(forKey: Keys.meals.rawValue) ?? []
        all.removeAll { $0.id == mealId }
        storage.save(all, forKey: Keys.meals.rawValue)
    }
}
