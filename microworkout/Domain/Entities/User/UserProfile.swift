//
//  UserProfile.swift
//  microworkout
//

import Foundation

struct UserProfile: Codable {
    var name: String
    var height: Double          // cm
    var weight: Double          // kg
    var age: Int
    var gender: Gender
    var activityLevel: ActivityLevel

    enum Gender: String, Codable, CaseIterable {
        case male = "Hombre"
        case female = "Mujer"
    }

    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary = "Sedentario"
        case light = "Ligeramente activo"
        case moderate = "Moderadamente activo"
        case active = "Activo"
        case veryActive = "Muy activo"

        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .light: return 1.375
            case .moderate: return 1.55
            case .active: return 1.725
            case .veryActive: return 1.9
            }
        }
    }

    /// Calcula las calorías diarias objetivo usando la fórmula Mifflin-St Jeor.
    var dailyCalorieTarget: Double {
        let bmr: Double
        switch gender {
        case .male:
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        case .female:
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) - 161
        }
        return bmr * activityLevel.multiplier
    }
}
