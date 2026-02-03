//
//  MealType.swift
//  microworkout
//

import Foundation

public enum MealType: String, CaseIterable, Identifiable, Codable {
    case breakfast = "Desayuno"
    case lunch = "Almuerzo"
    case dinner = "Cena"
    case snack = "Snack"

    public var id: Self { self }

    public var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }
}
