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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(object) {
            defaults.set(data, forKey: key)
        }
    }

    func get<T: Codable>(forKey key: String) -> T? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
