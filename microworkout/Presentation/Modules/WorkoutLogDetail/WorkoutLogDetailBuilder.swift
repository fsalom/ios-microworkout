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
            healthUseCase: HealthContainer(component: component).makeUseCase()
        )
        return WorkoutLogDetailView(viewModel: viewModel)
    }
}
