import Foundation

/// Protocolo para acceder a la fuente de datos de entradas de entrenamiento.
/// Trabaja con DTOs — la conversión a/desde `WorkoutEntry` Domain la hace el
/// repositorio en su frontera.
protocol WorkoutEntryDataSourceProtocol {
    func getAll() async throws -> [WorkoutEntryDTO]
    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntryDTO]
    func add(_ entry: WorkoutEntryDTO) async throws
    func update(_ entry: WorkoutEntryDTO) async throws
    func delete(entryID: UUID) async throws
}
