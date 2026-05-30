import Foundation

class ExerciseUseCase: ExerciseUseCaseProtocol {
    private var repository: ExerciseRepositoryProtocol

    init(repository: ExerciseRepositoryProtocol) {
        self.repository = repository
    }

    func getAll(contains searchText: String) async throws -> [Exercise] {
        let exercises = try await self.repository.getExercises()
        return exercises.filter { searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) }
    }

    func create(with name: String) async throws -> Exercise {
        let draft = Exercise(name: name)
        return try await self.repository.create(draft)
    }
}
