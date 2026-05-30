protocol ExerciseUseCaseProtocol {
    func getAll(contains searchText: String) async throws -> [Exercise]
    func create(with name: String) async throws -> Exercise
}
