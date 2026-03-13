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
        // Pasamos el UserDefaultsManager desde el componente al data source.
        let linkingDataSource = WorkoutLinkLocalDataSource(userDefaults: component.makeUserDefaultsManager())
        return HealthUseCase(repository: healthRepository, linkingDataSource: linkingDataSource)
    }
}
