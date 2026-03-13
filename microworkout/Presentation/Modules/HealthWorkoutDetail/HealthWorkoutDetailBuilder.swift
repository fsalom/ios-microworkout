class HealthWorkoutDetailBuilder {
    func build(for workout: HealthWorkout) -> HealthWorkoutDetailView {
        let component = DefaultAppComponent()
        let viewModel = HealthWorkoutDetailViewModel(
            workout: workout,
            healthUseCase: HealthContainer(component: component).makeUseCase(),
            trainingUseCase: TrainingContainer(component: component).makeUseCase()
        )
        return HealthWorkoutDetailView(viewModel: viewModel)
    }
}
