import Foundation

/// Implementación del repositorio de entradas de entrenamiento.
/// Convierte Domain ↔ DTO en la frontera con el datasource.
class WorkoutEntryRepository: WorkoutEntryRepositoryProtocol {
    private let dataSource: WorkoutEntryDataSourceProtocol

    init(dataSource: WorkoutEntryDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func getAll() async throws -> [WorkoutEntry] {
        try await dataSource.getAll().map { $0.toDomain() }
    }

    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntry] {
        try await dataSource.getAll(for: exerciseID).map { $0.toDomain() }
    }

    func add(_ entry: WorkoutEntry) async throws {
        try await dataSource.add(entry.toDTO())
    }

    func update(_ entry: WorkoutEntry) async throws {
        try await dataSource.update(entry.toDTO())
    }

    func delete(entryID: UUID) async throws {
        try await dataSource.delete(entryID: entryID)
    }
}
