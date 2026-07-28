import Foundation

protocol ExerciseRepositoryProtocol {
    func getExercises(contains searchText: String) async throws -> [Exercise]
    func getExercises() async throws -> [Exercise]
    func create(_ exercise: Exercise) async throws -> Exercise
    func delete(_ id: UUID) async throws
    /// Cuántos ejercicios locales todavía no están en la cuenta (dedup por nombre).
    func pendingSyncCount() async throws -> Int
    /// Sube a la cuenta los ejercicios locales que aún no estén en el servidor
    /// (modelo espejo: no borra la copia local). Devuelve cuántos subió.
    func syncLocalToRemote() async throws -> Int
}
