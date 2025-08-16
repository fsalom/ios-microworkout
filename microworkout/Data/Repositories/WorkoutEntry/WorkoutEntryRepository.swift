import Foundation

/// Implementación del repositorio de entradas de entrenamiento.
class WorkoutEntryRepository: WorkoutEntryRepositoryProtocol {
    private let dataSource: WorkoutEntryDataSourceProtocol

    init(dataSource: WorkoutEntryDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func getAll() async throws -> [WorkoutEntry] {
        try await dataSource.getAll()
    }

    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntry] {
        try await dataSource.getAll(for: exerciseID)
    }

    func add(_ entry: WorkoutEntry) async throws {
        try await dataSource.add(entry)
    }

    func update(_ entry: WorkoutEntry) async throws {
        try await dataSource.update(entry)
    }

    func delete(entryID: UUID) async throws {
        try await dataSource.delete(entryID: entryID)
    }
}