//
//  Meal.swift
//  microworkout
//

import Foundation

public struct Meal: Identifiable, Hashable, Codable {
    public let id: UUID
    public var type: MealType
    public var timestamp: Date
    public var items: [FoodItem]
    /// Name of the saved "Mi comida" recipe this meal was added from.
    /// `nil` for ad-hoc meals built ingredient by ingredient.
    public var myMealName: String?

    public init(
        id: UUID = UUID(),
        type: MealType,
        timestamp: Date = Date(),
        items: [FoodItem] = [],
        myMealName: String? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.items = items
        self.myMealName = myMealName
    }

    /// Total nutrition from all food items
    public var totalNutrition: NutritionInfo {
        items.reduce(NutritionInfo.zero) { $0 + $1.actualNutrition }
    }

    /// Formatted time string (HH:mm)
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Meal, rhs: Meal) -> Bool {
        lhs.id == rhs.id
    }
}
