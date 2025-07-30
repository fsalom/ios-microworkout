

class CurrentSessionBuilder {
    func build() -> CurrentSessionView {
        let loggedExerciseDataSource: LoggedExerciseDataSourceProtocol = LoggedExerciseMemoryDataSource()
        let loggedExerciseRepository: LoggedExerciseRepositoryProtocol = LoggedExerciseRepository(dataSource: loggedExerciseDataSource)
        let loggedExerciseUseCase: LoggedExerciseUseCaseProtocol = LoggedExerciseUseCase(repository: loggedExerciseRepository)
        let mockExerciseDataSource: ExerciseDataSourceProtocol = ExerciseMockDataSource()
        let exerciseRepository: ExerciseRepositoryProtocol = ExerciseRepository(dataSource: mockExerciseDataSource)
        let exerciseUseCases: ExerciseUseCaseProtocol = ExerciseUseCase(repository: exerciseRepository)
        let viewModel = CurrentSessionViewModel(exerciseUseCase: exerciseUseCases, loggedExerciseUseCase: loggedExerciseUseCase)
        return CurrentSessionView(viewModel: viewModel)
    }
}
