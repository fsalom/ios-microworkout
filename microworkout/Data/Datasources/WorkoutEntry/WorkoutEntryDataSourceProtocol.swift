import Foundation

/// Protocolo para acceder a la fuente de datos de entradas de entrenamiento.
public protocol WorkoutEntryDataSourceProtocol {
    /// Recupera todas las entradas de entrenamiento.
    func getAll() async throws -> [WorkoutEntry]

    /// Recupera las entradas asociadas a un ejercicio específico.
    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntry]

    /// Añade una nueva entrada de entrenamiento.
    func add(_ entry: WorkoutEntry) async throws

    /// Actualiza una entrada de entrenamiento existente.
    func update(_ entry: WorkoutEntry) async throws

    /// Elimina la entrada con el identificador dado.
    func delete(entryID: UUID) async throws
}