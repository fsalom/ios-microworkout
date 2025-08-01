class LoggedExerciseContainer {
    func makeUseCase() -> LoggedExerciseUseCase {
        let memory = LoggedExerciseInMemory.shared
        let loggedExerciseMemoryDataSource: LoggedExerciseDataSourceProtocol
        = LoggedExerciseMemoryDataSource(memory: memory)
        let userDefaults = UserDefaultsManager()
        let loggedExerciseUserDefaultsDataSource: LoggedExerciseDataSourceProtocol
        = LoggedExerciseLocalDataSource(localStorage: userDefaults)
        let loggedExerciseRepository: LoggedExerciseRepositoryProtocol
        = LoggedExerciseRepository(memory: loggedExerciseMemoryDataSource,
                                   local: loggedExerciseUserDefaultsDataSource)
        return LoggedExerciseUseCase(repository: loggedExerciseRepository)
    }
}
