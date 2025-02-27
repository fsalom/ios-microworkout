import Foundation

protocol UserDefaultsManagerProtocol {
    func save<T: Codable>(_ object: T, forKey key: String)
    func get<T: Codable>(forKey key: String) -> T?
    func remove(forKey key: String)
}

class UserDefaultsManager: UserDefaultsManagerProtocol {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save<T: Codable>(_ object: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(object) {
            defaults.set(data, forKey: key)
        }
    }

    func get<T: Codable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
