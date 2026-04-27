import Foundation

/// User-defined meal recipe: a named collection of food items the user can save
/// and later quick-add as a single meal.
public struct MyMeal: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var items: [FoodItem]
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, items: [FoodItem], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.items = items
        self.createdAt = createdAt
    }

    public var totalNutrition: NutritionInfo {
        items.reduce(NutritionInfo.zero) { $0 + $1.actualNutrition }
    }
}
