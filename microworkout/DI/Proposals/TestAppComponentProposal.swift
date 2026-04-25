// Proposal: AppComponent de pruebas (TestAppComponent) y mocks in-memory
// Este archivo es una propuesta. No modifica archivos existentes; muestra implementaciones de test.

import Foundation
import HealthKit

// Mock in-memory de UserDefaultsManagerProtocol para tests rápidos.
final class InMemoryUserDefaultsManager: UserDefaultsManagerProtocol {
    private var storage: [String: Data] = [:]
    private let queue = DispatchQueue(label: "InMemoryUserDefaultsManager")

    func save<T: Codable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(object) {
            queue.sync { storage[key] = data }
        }
    }

    func get<T: Codable>(forKey key: String) -> T? {
        queue.sync {
            guard let data = storage[key] else { return nil }
            let decoder = JSONDecoder()
            return try? decoder.decode(T.self, from: data)
        }
    }

    func remove(forKey key: String) {
        queue.sync { storage.removeValue(forKey: key) }
    }
}

// Mock básico para HealthKitManagerProtocol que permite tests sin HealthKit.
final class MockHealthKitManager: HealthKitManagerProtocol {
    var store: HealthStoreProtocol { MockHealthStore() }
    var isHealthDataAvailable: Bool { false }
    var authorizationStatus: HKAuthorizationStatus { .notDetermined }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }
    func fetchStepCount(completion: @escaping (Double?, Error?) -> Void) {
        completion(nil, nil)
    }
    func fetchStepCount(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void) {
        completion(nil, nil)
    }
    func fetchLatestHeartRate(completion: @escaping (Double?, Error?) -> Void) {
        completion(nil, nil)
    }
    func fetchExerciseTimeToday(completion: @escaping (Double?, Error?) -> Void) {
        completion(nil, nil)
    }
    func fetchExerciseTime(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void) {
        completion(nil, nil)
    }
    func fetchStandingTime(completion: @escaping (Double?, Error?) -> Void) {
        completion(nil, nil)
    }
    func fetchStandingTime(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void) {
        completion(nil, nil)
    }
    func fetchWorkouts(completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        completion(nil, nil)
    }
    func fetchAverageHeartRate(for workout: HKWorkout, completion: @escaping (Double?) -> Void) {
        completion(nil)
    }
}

// Test AppComponent que inyecta mocks.
struct TestAppComponent: AppComponentProtocol {
    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol {
        return InMemoryUserDefaultsManager()
    }

    func makeHealthKitManager() -> HealthKitManagerProtocol {
        return MockHealthKitManager()
    }
}
