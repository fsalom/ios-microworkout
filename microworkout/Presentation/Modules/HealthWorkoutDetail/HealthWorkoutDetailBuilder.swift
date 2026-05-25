class HealthWorkoutDetailBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(for workout: HealthWorkout) -> HealthWorkoutDetailView {
        let viewModel = HealthWorkoutDetailViewModel(
            workout: workout,
            router: HealthWorkoutDetailRouter(navigator: Navigator.shared, component: component),
            healthUseCase: component.healthUseCase,
            trainingUseCase: component.trainingUseCase,
            workoutEntryUseCase: component.workoutEntryUseCase,
            workoutLogUseCase: component.workoutLogUseCase
        )
        return HealthWorkoutDetailView(viewModel: viewModel)
    }
}
