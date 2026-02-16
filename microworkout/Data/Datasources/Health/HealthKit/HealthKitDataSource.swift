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
}
