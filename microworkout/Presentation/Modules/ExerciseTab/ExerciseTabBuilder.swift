import Foundation

class ExerciseTabBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> ExerciseTabView {
        let viewModel = ExerciseTabViewModel(
            router: ExerciseTabRouter(navigator: Navigator.shared, component: component),
            healthUseCase: component.healthUseCase,
            workoutEntryUseCase: component.workoutEntryUseCase,
            workoutLogUseCase: component.workoutLogUseCase,
            coachUseCase: component.coachUseCase
        )
        return ExerciseTabView(viewModel: viewModel)
    }
}
