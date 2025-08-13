import Foundation

/// Protocolo para acceder al repositorio de entradas de entrenamiento.
protocol WorkoutEntryRepositoryProtocol {
    func getAll() async throws -> [WorkoutEntry]
    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntry]
    func add(_ entry: WorkoutEntry) async throws
    func update(_ entry: WorkoutEntry) async throws
    func delete(entryID: UUID) async throws
}