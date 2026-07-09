import Foundation

protocol ExerciseRepositoryProtocol {
    func getExercises(contains searchText: String) async throws -> [Exercise]
    func getExercises() async throws -> [Exercise]
    func create(_ exercise: Exercise) async throws -> Exercise
    func delete(_ id: UUID) async throws
    func uploadLocalToRemote() async throws -> Int
}
