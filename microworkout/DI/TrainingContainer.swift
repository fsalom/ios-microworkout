import Foundation

class TrainingContainer {
    func makeUseCase() -> TrainingUseCaseProtocol {
        let trainingLocalDataSource = TrainingLocalDataSource(localStorage: UserDefaultsManager())
        let trainingRepository = TrainingRepository(local: trainingLocalDataSource)
        return TrainingUseCase(repository: trainingRepository)
    }
}
