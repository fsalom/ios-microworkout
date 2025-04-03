class HealthContainer {
    func makeUseCase() -> HealthUseCase {
        let HealthDataSource = HealthKitDataSource(healthKitManager: HealthKitManager.shared)
        let healthRepository = HealthRepository(dataSource: HealthDataSource)
        return HealthUseCase(repository: healthRepository)
    }
}
