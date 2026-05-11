import Foundation

class WorkoutLogDetailBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(log: WorkoutLog) -> WorkoutLogDetailView {
        let viewModel = WorkoutLogDetailViewModel(
            log: log,
            useCase: WorkoutLogContainer(component: component).makeUseCase(),
            healthUseCase: HealthContainer(component: component).makeUseCase(),
            router: WorkoutLogDetailRouter(
                navigator: Navigator.shared,
                component: component
            ),
            mediaUseCase: SetMediaContainer(component: component).makeUseCase()
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
}
