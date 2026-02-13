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
    var fitnessGoal: FitnessGoal?
    var macroProfile: MacroProfile?
    var freeDays: [Int]?              // weekday indices (Calendar: 1=Dom, 2=Lun...7=Sab)
    var freeDayExtraCalories: Double? // extra kcal por día libre, default 500

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

    enum FitnessGoal: String, Codable, CaseIterable {
        case loseWeight = "Perder peso"
        case maintain = "Mantener"
        case gainMuscle = "Ganar musculo"

        var calorieAdjustment: Double {
            switch self {
            case .loseWeight: return -500
            case .maintain: return 0
            case .gainMuscle: return 300
            }
        }

        var proteinPerKg: Double {
            switch self {
            case .loseWeight, .gainMuscle: return 2.0
            case .maintain: return 1.6
            }
        }
    }

    enum MacroProfile: String, Codable, CaseIterable {
        case balanced = "Equilibrado"
        case lowCarb = "Low carb"
    }

    var resolvedGoal: FitnessGoal {
        fitnessGoal ?? .maintain
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
        return bmr * activityLevel.multiplier + resolvedGoal.calorieAdjustment
    }

    var resolvedMacroProfile: MacroProfile {
        macroProfile ?? .balanced
    }

    var macroTargets: NutritionInfo {
        macrosForCalories(dailyCalorieTarget)
    }

    // MARK: - Cycling semanal

    var resolvedFreeDays: Set<Int> {
        Set(freeDays ?? [])
    }

    var resolvedFreeDayExtra: Double {
        freeDayExtraCalories ?? 500
    }

    var hasCycling: Bool {
        !resolvedFreeDays.isEmpty
    }

    var freeDayCalorieTarget: Double {
        dailyCalorieTarget + resolvedFreeDayExtra
    }

    var strictDayCalorieTarget: Double {
        let weeklyBudget = dailyCalorieTarget * 7
        let freeDayCount = Double(resolvedFreeDays.count)
        let strictDayCount = 7 - freeDayCount
        guard strictDayCount > 0 else { return dailyCalorieTarget }
        return (weeklyBudget - freeDayCalorieTarget * freeDayCount) / strictDayCount
    }

    var todayIsFreeDay: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return resolvedFreeDays.contains(weekday)
    }

    var todayCalorieTarget: Double {
        guard hasCycling else { return dailyCalorieTarget }
        return todayIsFreeDay ? freeDayCalorieTarget : strictDayCalorieTarget
    }

    var todayMacroTargets: NutritionInfo {
        macrosForCalories(todayCalorieTarget)
    }

    // MARK: - Private

    private func macrosForCalories(_ calories: Double) -> NutritionInfo {
        let proteinGrams = resolvedGoal.proteinPerKg * weight
        let proteinCalories = proteinGrams * 4

        let fatGrams: Double
        let carbGrams: Double

        switch resolvedMacroProfile {
        case .balanced:
            fatGrams = 0.9 * weight
            let fatCalories = fatGrams * 9
            carbGrams = max(calories - proteinCalories - fatCalories, 0) / 4
        case .lowCarb:
            carbGrams = max(calories * 0.25, 0) / 4
            let carbCalories = carbGrams * 4
            fatGrams = max(calories - proteinCalories - carbCalories, 0) / 9
        }

        return NutritionInfo(
            calories: calories,
            carbohydrates: carbGrams,
            proteins: proteinGrams,
            fats: fatGrams
        )
    }
}
