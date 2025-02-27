import Foundation

class TrainingContainer {
    func makeUseCase() -> TrainingUseCase {
        let trainingLocalDataSource = TrainingLocalDataSource(localStorage: UserDefaultsManager())
        let trainingRepository = TrainingRepository(local: trainingLocalDataSource)
        return TrainingUseCase(repository: trainingRepository)
    }
}
