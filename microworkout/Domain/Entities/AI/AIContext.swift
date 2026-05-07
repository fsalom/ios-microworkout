import Foundation

/// Snapshot serializable de TODA la información que la app puede enviar a un
/// asistente IA para análisis del histórico y orientación futura.
///
/// Todos los snapshots son `Codable` y planos, sin lógica derivada, para
/// minimizar tokens y poder serializarlos a JSON predecible.
public struct AIContext: Codable {
    public var generatedAt: Date
    public var locale: String
    public var profile: AIProfileSnapshot?
    public var workoutSessions: [AIWorkoutSessionSnapshot]
    public var workoutLogs: [AIWorkoutLogSnapshot]
    public var manualEntries: [AIWorkoutEntrySnapshot]
    public var meals: [AIMealSnapshot]
    public var healthDays: [AIHealthDaySnapshot]
    public var healthWorkouts: [AIHealthWorkoutSnapshot]

    public init(
        generatedAt: Date = Date(),
        locale: String = Locale.current.identifier,
        profile: AIProfileSnapshot? = nil,
        workoutSessions: [AIWorkoutSessionSnapshot] = [],
        workoutLogs: [AIWorkoutLogSnapshot] = [],
        manualEntries: [AIWorkoutEntrySnapshot] = [],
        meals: [AIMealSnapshot] = [],
        healthDays: [AIHealthDaySnapshot] = [],
        healthWorkouts: [AIHealthWorkoutSnapshot] = []
    ) {
        self.generatedAt = generatedAt
        self.locale = locale
        self.profile = profile
        self.workoutSessions = workoutSessions
        self.workoutLogs = workoutLogs
        self.manualEntries = manualEntries
        self.meals = meals
        self.healthDays = healthDays
        self.healthWorkouts = healthWorkouts
    }
}

// MARK: - Profile

public struct AIProfileSnapshot: Codable {
    public var name: String
    public var age: Int
    public var gender: String
    public var heightCm: Double
    public var weightKg: Double
    public var activityLevel: String
    public var fitnessGoal: String?
    public var dailyCalorieTarget: Double
    public var todayCalorieTarget: Double
    public var macroTargets: AINutritionSnapshot
    public var hasWeeklyCycling: Bool
    public var freeDaysWeekdays: [Int]?
    public var freeDayExtraCalories: Double?
}

// MARK: - Nutrition

public struct AINutritionSnapshot: Codable {
    public var calories: Double
    public var carbohydratesG: Double
    public var proteinsG: Double
    public var fatsG: Double
    public var fiberG: Double?
}

// MARK: - Workout templates / sessions

public struct AIWorkoutSessionSnapshot: Codable {
    public var id: String
    public var name: String
    public var exercises: [String]
    public var createdAt: Date
    public var updatedAt: Date
}

// MARK: - Workout logs (template-based registered workouts)

public struct AIWorkoutLogSnapshot: Codable {
    public var id: String
    public var sessionId: String?
    public var sessionName: String
    public var startedAt: Date
    public var endedAt: Date?
    public var durationSeconds: Int?
    public var linkedHealthWorkoutId: String?
    public var exercises: [AILoggedExerciseSnapshot]
}

public struct AILoggedExerciseSnapshot: Codable {
    public var name: String
    public var notes: String?
    public var sets: [AILoggedSetSnapshot]
}

public struct AILoggedSetSnapshot: Codable {
    public var weightKg: Double?
    public var reps: Int?
    public var rir: Float?
}

// MARK: - Manual ad-hoc workout entries (CurrentSession registry)

public struct AIWorkoutEntrySnapshot: Codable {
    public var id: String
    public var exerciseName: String
    public var date: Date
    public var reps: Int?
    public var weightKg: Double?
    public var distanceMeters: Double?
    public var calories: Double?
    public var completed: Bool
}

// MARK: - Meals

public struct AIMealSnapshot: Codable {
    public var id: String
    public var type: String
    public var timestamp: Date
    public var myMealName: String?
    public var totalNutrition: AINutritionSnapshot
    public var items: [AIFoodItemSnapshot]
}

public struct AIFoodItemSnapshot: Codable {
    public var name: String
    public var quantityG: Double
    public var nutrition: AINutritionSnapshot
}

// MARK: - Health (Apple Watch / iPhone Salud)

public struct AIHealthDaySnapshot: Codable {
    public var date: Date
    public var steps: Int
    public var minutesOfExercise: Int
    public var minutesStanding: Int
}

public struct AIHealthWorkoutSnapshot: Codable {
    public var id: String
    public var activityType: String
    public var startDate: Date
    public var endDate: Date
    public var durationSeconds: Double
    public var totalCalories: Double?
    public var totalDistanceMeters: Double?
    public var averageHeartRate: Double?
    public var linkedTrainingId: String?
    public var linkedEntryDate: String?
}
