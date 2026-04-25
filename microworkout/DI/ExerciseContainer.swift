class ExerciseContainer {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> ExerciseUseCase {
        let mockExerciseDataSource: ExerciseDataSourceProtocol = ExerciseMockDataSource()
        let exerciseRepository: ExerciseRepositoryProtocol = ExerciseRepository(dataSource: mockExerciseDataSource)
        return ExerciseUseCase(repository: exerciseRepository)
    }
}
