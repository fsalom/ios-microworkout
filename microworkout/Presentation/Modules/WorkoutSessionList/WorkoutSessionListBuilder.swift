import Foundation

class WorkoutSessionListBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> WorkoutSessionListView {
        let viewModel = WorkoutSessionListViewModel(
            router: WorkoutSessionListRouter(navigator: Navigator.shared, component: component),
            useCase: component.workoutLogUseCase
        )
        return WorkoutSessionListView(viewModel: viewModel)
    }
}
