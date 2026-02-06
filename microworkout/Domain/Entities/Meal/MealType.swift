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

    public static func forCurrentTime() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<10: return .breakfast
        case 10..<15: return .lunch
        case 15..<21: return .dinner
        default: return .snack
        }
    }
}
