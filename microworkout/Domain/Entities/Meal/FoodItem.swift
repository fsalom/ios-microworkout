//
//  FoodItem.swift
//  microworkout
//

import Foundation

public struct FoodItem: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var barcode: String?
    public var nutritionPer100g: NutritionInfo
    public var quantity: Double // in grams
    public var servingSize: Double?
    public var imageUrl: String?

    public init(
        id: UUID = UUID(),
        name: String,
        barcode: String? = nil,
        nutritionPer100g: NutritionInfo = NutritionInfo(),
        quantity: Double = 100,
        servingSize: Double? = nil,
        imageUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.barcode = barcode
        self.nutritionPer100g = nutritionPer100g
        self.quantity = quantity
        self.servingSize = servingSize
        self.imageUrl = imageUrl
    }

    /// Actual nutrition based on quantity
    public var actualNutrition: NutritionInfo {
        nutritionPer100g.scaled(by: quantity / 100.0)
    }

    /// Formatted quantity string
    public var formattedQuantity: String {
        if quantity == floor(quantity) {
            return "\(Int(quantity))g"
        }
        return String(format: "%.1fg", quantity)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: FoodItem, rhs: FoodItem) -> Bool {
        lhs.id == rhs.id
    }
}
