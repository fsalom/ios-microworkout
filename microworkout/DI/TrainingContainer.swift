import Foundation

class TrainingContainer {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> TrainingUseCaseProtocol {
        let trainingLocalDataSource = TrainingLocalDataSource(localStorage: component.makeUserDefaultsManager())
        let trainingRepository = TrainingRepository(local: trainingLocalDataSource)
        return TrainingUseCase(repository: trainingRepository)
    }
}
