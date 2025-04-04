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

    func fetchHoursStandingCount() async throws -> Double? {
        return try await withCheckedThrowingContinuation { continuation in
            self.healthKitManager.fetchHoursStandingCount { hours, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: hours)
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
}
