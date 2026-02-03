//
//  NutritionInfo.swift
//  microworkout
//

import Foundation

public struct NutritionInfo: Codable, Equatable {
    public var calories: Double
    public var carbohydrates: Double
    public var proteins: Double
    public var fats: Double
    public var fiber: Double?

    public init(
        calories: Double = 0,
        carbohydrates: Double = 0,
        proteins: Double = 0,
        fats: Double = 0,
        fiber: Double? = nil
    ) {
        self.calories = calories
        self.carbohydrates = carbohydrates
        self.proteins = proteins
        self.fats = fats
        self.fiber = fiber
    }

    /// Returns nutrition info scaled by a factor (e.g., for quantity adjustments)
    public func scaled(by factor: Double) -> NutritionInfo {
        NutritionInfo(
            calories: calories * factor,
            carbohydrates: carbohydrates * factor,
            proteins: proteins * factor,
            fats: fats * factor,
            fiber: fiber.map { $0 * factor }
        )
    }

    public static func + (lhs: NutritionInfo, rhs: NutritionInfo) -> NutritionInfo {
        NutritionInfo(
            calories: lhs.calories + rhs.calories,
            carbohydrates: lhs.carbohydrates + rhs.carbohydrates,
            proteins: lhs.proteins + rhs.proteins,
            fats: lhs.fats + rhs.fats,
            fiber: {
                switch (lhs.fiber, rhs.fiber) {
                case let (l?, r?): return l + r
                case let (l?, nil): return l
                case let (nil, r?): return r
                case (nil, nil): return nil
                }
            }()
        )
    }

    public static var zero: NutritionInfo {
        NutritionInfo()
    }
}
