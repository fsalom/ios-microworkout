class HealthContainer {
    private let component: AppComponentProtocol

    // Forzar inyección del componente: eliminar el valor por defecto que crea DefaultAppComponent.
    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> HealthUseCase {
        // Ahora obtenemos el HealthKitManager desde el componente, permitiendo tests
        // con mocks o variaciones de implementación.
        let healthManager = component.makeHealthKitManager()
        let healthDataSource = HealthKitDataSource(healthKitManager: healthManager)
        let healthRepository = HealthRepository(dataSource: healthDataSource)
        let linkDataSource = WorkoutLinkLocalDataSource(userDefaults: component.makeUserDefaultsManager())
        let linkRepository = WorkoutLinkRepository(dataSource: linkDataSource)
        return HealthUseCase(repository: healthRepository, linkRepository: linkRepository)
    }
}
