import Foundation

/// Persistencia de comidas usando UserDefaults. Trabaja con DTOs en lugar de
/// entidades de Domain para que el formato on-disk sea independiente de
/// refactors en `Meal`/`FoodItem`/`NutritionInfo`.
class MealLocalDataSource: MealDataSourceProtocol {
    private let storage: UserDefaultsManagerProtocol

    private enum Keys: String {
        case meals
        case favorites = "favoriteFoods"
        case myMeals
        case customFoods = "customFoodsByBarcode"
    }

    init(storage: UserDefaultsManagerProtocol) {
        self.storage = storage
    }

    // MARK: Meals

    func saveMeal(_ meal: MealDTO) async throws {
        var all: [MealDTO] = storage.get(forKey: Keys.meals.rawValue) ?? []
        if let idx = all.firstIndex(where: { $0.id == meal.id }) {
            all[idx] = meal
        } else {
            all.append(meal)
        }
        storage.save(all, forKey: Keys.meals.rawValue)
    }

    func getAllMeals() async throws -> [MealDTO] {
        storage.get(forKey: Keys.meals.rawValue) ?? []
    }

    func getMeals(for date: Date) async throws -> [MealDTO] {
        let all: [MealDTO] = storage.get(forKey: Keys.meals.rawValue) ?? []
        let calendar = Calendar.current
        return all.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }

    func getMeals(from startDate: Date, to endDate: Date) async throws -> [MealDTO] {
        let all: [MealDTO] = storage.get(forKey: Keys.meals.rawValue) ?? []
        return all.filter { meal in
            meal.timestamp >= startDate && meal.timestamp <= endDate
        }
    }

    func deleteMeal(_ mealId: UUID) async throws {
        var all: [MealDTO] = storage.get(forKey: Keys.meals.rawValue) ?? []
        all.removeAll { $0.id == mealId }
        storage.save(all, forKey: Keys.meals.rawValue)
    }

    // MARK: Favorites

    func getFavorites() -> [FoodItemDTO] {
        storage.get(forKey: Keys.favorites.rawValue) ?? []
    }

    func saveFavorites(_ favorites: [FoodItemDTO]) {
        storage.save(favorites, forKey: Keys.favorites.rawValue)
    }

    // MARK: My meals

    func getMyMeals() -> [MyMealDTO] {
        storage.get(forKey: Keys.myMeals.rawValue) ?? []
    }

    func saveMyMeals(_ meals: [MyMealDTO]) {
        storage.save(meals, forKey: Keys.myMeals.rawValue)
    }

    // MARK: Custom foods

    func getCustomFoods() -> [String: FoodItemDTO] {
        storage.get(forKey: Keys.customFoods.rawValue) ?? [:]
    }

    func saveCustomFoods(_ foods: [String: FoodItemDTO]) {
        storage.save(foods, forKey: Keys.customFoods.rawValue)
    }
}
