import Foundation

/// Persistencia de WorkoutEntry usando UserDefaults.
class WorkoutEntryLocalDataSource: WorkoutEntryDataSourceProtocol {
    private let storage: UserDefaultsManagerProtocol

    private enum Keys: String {
        case entries
    }

    init(storage: UserDefaultsManagerProtocol = UserDefaultsManager()) {
        self.storage = storage
    }

    func getAll() async throws -> [WorkoutEntry] {
        storage.get(forKey: Keys.entries.rawValue) ?? []
    }

    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntry] {
        let all: [WorkoutEntry] = storage.get(forKey: Keys.entries.rawValue) ?? []
        return all.filter { $0.exercise.id == exerciseID }
    }

    func add(_ entry: WorkoutEntry) async throws {
        var all: [WorkoutEntry] = storage.get(forKey: Keys.entries.rawValue) ?? []
        all.append(entry)
        storage.save(all, forKey: Keys.entries.rawValue)
    }

    func update(_ entry: WorkoutEntry) async throws {
        var all: [WorkoutEntry] = storage.get(forKey: Keys.entries.rawValue) ?? []
        if let idx = all.firstIndex(where: { $0.id == entry.id }) {
            all[idx] = entry
            storage.save(all, forKey: Keys.entries.rawValue)
        }
    }

    func delete(entryID: UUID) async throws {
        var all: [WorkoutEntry] = storage.get(forKey: Keys.entries.rawValue) ?? []
        all.removeAll { $0.id == entryID }
        storage.save(all, forKey: Keys.entries.rawValue)
    }
}