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

    public init(
        id: UUID = UUID(),
        type: MealType,
        timestamp: Date = Date(),
        items: [FoodItem] = []
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.items = items
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
