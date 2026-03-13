import Foundation

/// Contenedor de dependencias para casos de uso de entradas de entrenamiento.
/// Ahora acepta un AppComponentProtocol para provisión de dependencias.
class WorkoutEntryContainer {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> WorkoutEntryUseCase {
        let storage = component.makeUserDefaultsManager()
        let localDataSource = WorkoutEntryLocalDataSource(storage: storage)
        let repository = WorkoutEntryRepository(dataSource: localDataSource)
        return WorkoutEntryUseCase(repository: repository)
    }
}
