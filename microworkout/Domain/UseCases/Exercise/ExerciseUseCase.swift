import Foundation

class ExerciseUseCase: ExerciseUseCaseProtocol {
    private var repository: ExerciseRepositoryProtocol

    init(repository: ExerciseRepositoryProtocol) {
        self.repository = repository
    }

    func getAll(contains searchText: String) async throws -> [Exercise] {
        let exercises = try await self.repository.getExercises()
        return exercises.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    func create(with name: String) async throws -> Exercise {
        return Exercise(name: name)
    }
}
