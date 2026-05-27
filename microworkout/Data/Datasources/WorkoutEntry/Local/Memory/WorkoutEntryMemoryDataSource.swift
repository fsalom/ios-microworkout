import Foundation

/// Implementación en memoria para pruebas de `WorkoutEntryDataSourceProtocol`.
class WorkoutEntryMemoryDataSource: WorkoutEntryDataSourceProtocol {
    private var storage: [WorkoutEntryDTO] = []

    func getAll() async throws -> [WorkoutEntryDTO] {
        storage
    }

    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntryDTO] {
        storage.filter { $0.exercise.id == exerciseID }
    }

    func add(_ entry: WorkoutEntryDTO) async throws {
        storage.append(entry)
    }

    func update(_ entry: WorkoutEntryDTO) async throws {
        if let idx = storage.firstIndex(where: { $0.id == entry.id }) {
            storage[idx] = entry
        }
    }

    func delete(entryID: UUID) async throws {
        storage.removeAll { $0.id == entryID }
    }
}
