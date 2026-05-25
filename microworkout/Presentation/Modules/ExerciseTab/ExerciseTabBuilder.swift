import Foundation

class ExerciseTabBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> ExerciseTabView {
        let viewModel = ExerciseTabViewModel(
            router: ExerciseTabRouter(navigator: Navigator.shared, component: component),
            healthUseCase: HealthContainer(component: component).makeUseCase(),
            workoutEntryUseCase: WorkoutEntryContainer(component: component).makeUseCase(),
            workoutLogUseCase: WorkoutLogContainer(component: component).makeUseCase(),
            coachUseCase: CoachContainer(component: component).makeUseCase()
        )
        return ExerciseTabView(viewModel: viewModel)
    }
}
