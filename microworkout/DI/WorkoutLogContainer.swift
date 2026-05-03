import Foundation

class WorkoutLogContainer {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> WorkoutLogUseCaseProtocol {
        let local = WorkoutLogLocalDataSource(localStorage: component.makeUserDefaultsManager())
        let repository = WorkoutLogRepository(local: local)
        return WorkoutLogUseCase(repository: repository)
    }
}
