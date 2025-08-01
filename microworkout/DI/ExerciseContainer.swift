class ExerciseContainer {
    func makeUseCase() -> ExerciseUseCase {
        let mockExerciseDataSource: ExerciseDataSourceProtocol = ExerciseMockDataSource()
        let exerciseRepository: ExerciseRepositoryProtocol = ExerciseRepository(dataSource: mockExerciseDataSource)
        return ExerciseUseCase(repository: exerciseRepository)
    }
}
