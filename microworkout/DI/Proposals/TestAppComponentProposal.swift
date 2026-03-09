// Proposal: AppComponent de pruebas (TestAppComponent) y mocks in-memory
// Este archivo es una propuesta. No modifica archivos existentes; muestra implementaciones de test.

import Foundation

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
    // Implementar métodos mínimos si los tests los requieren.
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
