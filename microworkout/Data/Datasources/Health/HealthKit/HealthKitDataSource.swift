import Foundation
import HealthKit

enum HealthKitError: Error {
    case notAuthorized
}

class HealthKitDataSource: HealthKitDataSourceProtocol {
    
    var healthKitManager: HealthKitManager

    init(healthKitManager: HealthKitManager) {
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
        return try await withCheckedThrowingContinuation { continuation in
            self.healthKitManager.requestAuthorization { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    func fetchStepsCountToday() async throws -> Double? {
        return try await withCheckedThrowingContinuation { continuation in
            self.healthKitManager.fetchStepCount { steps, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: steps)
                }
            }
        }
    }

    func fetchStepsCount(startDate: Date, endDate: Date) async throws -> [Date : Double]? {
        return try await withCheckedThrowingContinuation { continuation in
            self.healthKitManager.fetchStepCount(startDate: startDate, endDate: endDate) { steps, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: steps)
                }
            }
        }
    }

    func fetchStandingTime() async throws -> Double? {
        return try await withCheckedThrowingContinuation { continuation in
            self.healthKitManager.fetchStandingTime { minutes, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: minutes)
                }
            }
        }
    }

    func fetchStandingTime(startDate: Date, endDate: Date) async throws -> [Date : Double]? {
        return try await withCheckedThrowingContinuation { continuation in
            self.healthKitManager.fetchStandingTime(startDate: startDate, endDate: endDate) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }

    func fetchExerciseTimeToday() async throws -> Double? {
        return try await withCheckedThrowingContinuation { continuation in
            self.healthKitManager.fetchExerciseTimeToday { steps, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: steps)
                }
            }
        }
    }

    func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date : Double]? {
        return try await withCheckedThrowingContinuation { continuation in
            self.healthKitManager.fetchExerciseTime(startDate: startDate, endDate: endDate) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }

    func fetchWorkouts() async throws -> [HealthWorkout] {
        let hkWorkouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            self.healthKitManager.fetchWorkouts { workouts, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: workouts ?? [])
                }
            }
        }

        var results: [HealthWorkout] = []
        for hkWorkout in hkWorkouts {
            let avgHR: Double? = await withCheckedContinuation { continuation in
                self.healthKitManager.fetchAverageHeartRate(for: hkWorkout) { hr in
                    continuation.resume(returning: hr)
                }
            }

            let calories = hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
            let distance = hkWorkout.totalDistance?.doubleValue(for: .meter())

            let workout = HealthWorkout(
                id: hkWorkout.uuid.uuidString,
                activityTypeName: Self.activityName(for: hkWorkout.workoutActivityType),
                startDate: hkWorkout.startDate,
                endDate: hkWorkout.endDate,
                durationInSeconds: hkWorkout.duration,
                totalCalories: calories,
                totalDistance: distance,
                averageHeartRate: avgHR
            )
            results.append(workout)
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
