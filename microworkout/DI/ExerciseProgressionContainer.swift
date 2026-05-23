import Foundation

class ExerciseProgressionContainer {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> ExerciseProgressionUseCaseProtocol {
        let logUseCase = WorkoutLogContainer(component: component).makeUseCase()
        let mediaUseCase = SetMediaContainer(component: component).makeUseCase()
        return ExerciseProgressionUseCase(
            logUseCase: logUseCase,
            mediaUseCase: mediaUseCase
        )
    }
}
