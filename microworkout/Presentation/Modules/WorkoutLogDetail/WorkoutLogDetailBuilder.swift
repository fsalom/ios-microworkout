import Foundation

class WorkoutLogDetailBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(log: WorkoutLog) -> WorkoutLogDetailView {
        let viewModel = WorkoutLogDetailViewModel(
            log: log,
            useCase: component.workoutLogUseCase,
            healthUseCase: component.healthUseCase,
            router: WorkoutLogDetailRouter(
                navigator: Navigator.shared,
                component: component
            ),
            mediaUseCase: component.setMediaUseCase
        )
        return WorkoutLogDetailView(viewModel: viewModel)
    }
}

final class WorkoutLogDetailRouter {
    private let navigator: NavigatorProtocol
    private let component: AppComponentProtocol

    init(navigator: NavigatorProtocol, component: AppComponentProtocol) {
        self.navigator = navigator
        self.component = component
    }

    func goToEdit(log: WorkoutLog) {
        navigator.push(to: WorkoutLogEntryBuilder(component: component).build(log: log, isNew: false))
    }

    func goToProgression(sourceSetId: UUID) {
        navigator.push(to: ExerciseProgressionBuilder(component: component).build(sourceSetId: sourceSetId))
    }
}
