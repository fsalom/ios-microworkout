class HealthContainer {
    func makeUseCase() -> HealthUseCase {
        let healthDataSource = HealthKitDataSource(healthKitManager: HealthKitManager.shared)
        let healthRepository = HealthRepository(dataSource: healthDataSource)
        let linkingDataSource = WorkoutLinkLocalDataSource()
        return HealthUseCase(repository: healthRepository, linkingDataSource: linkingDataSource)
    }
}
