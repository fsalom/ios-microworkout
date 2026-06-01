protocol ExerciseDataSourceProtocol {
    func getExercises() async throws -> [ExerciseDTO]
    func getExercises(contains searchText: String) async throws -> [ExerciseDTO]
    func create(_ exercise: ExerciseDTO) async throws -> ExerciseDTO
    func delete(_ id: String) async throws
}
