import Foundation

/// Implementación en memoria para pruebas de WorkoutEntryDataSourceProtocol.
class WorkoutEntryMemoryDataSource: WorkoutEntryDataSourceProtocol {
    private var storage: [WorkoutEntry] = []

    func getAll() async throws -> [WorkoutEntry] {
        storage
    }

    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntry] {
        storage.filter { $0.exercise.id == exerciseID }
    }

    func add(_ entry: WorkoutEntry) async throws {
        storage.append(entry)
    }

    func update(_ entry: WorkoutEntry) async throws {
        if let idx = storage.firstIndex(where: { $0.id == entry.id }) {
            storage[idx] = entry
        }
    }

    func delete(entryID: UUID) async throws {
        storage.removeAll { $0.id == entryID }
    }
}