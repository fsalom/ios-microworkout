import Foundation

class WorkoutHistoryBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> WorkoutHistoryView {
        let viewModel = WorkoutHistoryViewModel(
            router: WorkoutHistoryRouter(navigator: Navigator.shared, component: component),
            useCase: component.workoutLogUseCase
        )
        return WorkoutHistoryView(viewModel: viewModel)
    }
}
