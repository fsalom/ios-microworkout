import Foundation

/// Contenedor de dependencias para casos de uso de entradas de entrenamiento.
class WorkoutEntryContainer {
    func makeUseCase() -> WorkoutEntryUseCase {
        let storage = UserDefaultsManager()
        let localDataSource = WorkoutEntryLocalDataSource(storage: storage)
        let repository = WorkoutEntryRepository(dataSource: localDataSource)
        return WorkoutEntryUseCase(repository: repository)
    }
}