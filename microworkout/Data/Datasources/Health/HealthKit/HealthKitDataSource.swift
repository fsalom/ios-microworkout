import Foundation
import HealthKit

enum HealthKitError: Error {
    case notAuthorized
}

class HealthKitDataSource: HealthKitDataSourceProtocol {
    var healthKitManager: HealthKitManagerProtocol

    init(healthKitManager: HealthKitManagerProtocol) {
        self.healthKitManager = healthKitManager
    }

    var isHealthDataAvailable: Bool {
        healthKitManager.isHealthDataAvailable
    }

    var authorizationStatus: HealthAuthorizationStatus {
        switch healthKitManager.authorizationStatus {
        case .sharingAuthorized: return .authorized
        case .sharingDenied: return .denied
        default: return .notDetermined
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await healthKitManager.requestAuthorization()
    }

    func fetchStepsCountToday() async throws -> Double? {
        try await healthKitManager.fetchStepCount()
    }

    func fetchStepsCount(startDate: Date, endDate: Date) async throws -> [Date: Double]? {
        try await healthKitManager.fetchStepCount(startDate: startDate, endDate: endDate)
    }

    func fetchStandingTime() async throws -> Double? {
        try await healthKitManager.fetchStandingTime()
    }

    func fetchStandingTime(startDate: Date, endDate: Date) async throws -> [Date: Double]? {
        try await healthKitManager.fetchStandingTime(startDate: startDate, endDate: endDate)
    }

    func fetchExerciseTimeToday() async throws -> Double? {
        try await healthKitManager.fetchExerciseTimeToday()
    }

    func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date: Double]? {
        try await healthKitManager.fetchExerciseTime(startDate: startDate, endDate: endDate)
    }

    func fetchWorkouts() async throws -> [HealthWorkout] {
        let hkWorkouts = try await healthKitManager.fetchWorkouts()
        var results: [HealthWorkout] = []
        for hkWorkout in hkWorkouts {
            let avgHR = await healthKitManager.fetchAverageHeartRate(for: hkWorkout)
            let calories = hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
            let distance = hkWorkout.totalDistance?.doubleValue(for: .meter())
            results.append(HealthWorkout(
                id: hkWorkout.uuid.uuidString,
                activityTypeName: Self.activityName(for: hkWorkout.workoutActivityType),
                startDate: hkWorkout.startDate,
                endDate: hkWorkout.endDate,
                durationInSeconds: hkWorkout.duration,
                totalCalories: calories,
                totalDistance: distance,
                averageHeartRate: avgHR
            ))
        }
        return results
    }

    private static func activityName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Carrera"
        case .walking: return "Caminata"
        case .cycling: return "Ciclismo"
        case .swimming: return "Natacion"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Fuerza funcional"
        case .traditionalStrengthTraining: return "Fuerza"
        case .highIntensityIntervalTraining: return "HIIT"
        case .coreTraining: return "Core"
        case .elliptical: return "Eliptica"
        case .rowing: return "Remo"
        case .stairClimbing: return "Escaleras"
        case .flexibility: return "Flexibilidad"
        case .pilates: return "Pilates"
        case .dance: return "Baile"
        case .cooldown: return "Enfriamiento"
        case .mixedCardio: return "Cardio mixto"
        case .crossTraining: return "Cross training"
        case .soccer: return "Futbol"
        case .basketball: return "Basquetbol"
        case .tennis: return "Tenis"
        case .hiking: return "Senderismo"
        default: return "Ejercicio"
        }
    }
}
