class HealthWorkoutDetailBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(for workout: HealthWorkout) -> HealthWorkoutDetailView {
        let viewModel = HealthWorkoutDetailViewModel(
            workout: workout,
            healthUseCase: HealthContainer(component: component).makeUseCase(),
            trainingUseCase: TrainingContainer(component: component).makeUseCase()
        )
        return HealthWorkoutDetailView(viewModel: viewModel)
    }
}
