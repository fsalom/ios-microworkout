import Foundation

/// Casos de uso para gestionar entradas de entrenamiento.
protocol WorkoutEntryUseCaseProtocol {
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

    /// Elimina todas las entradas del día indicado.
    func deleteEntries(for day: WorkoutEntryByDay) async throws

    /// Agrupa todas las entradas por día.
    func getAllByDay() async throws -> [WorkoutEntryByDay]

    /// Agrupa las entradas por ejercicio y cuenta cuántas series hay.
    func groupByExercise(these entries: [WorkoutEntry]) -> [Exercise: [WorkoutEntry]]

    /// Ordena y extrae los ejercicios únicos según la fecha más reciente.
    func order(these entries: [WorkoutEntry]) -> [Exercise]
}