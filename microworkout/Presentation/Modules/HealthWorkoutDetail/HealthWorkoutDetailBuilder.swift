class HealthWorkoutDetailBuilder {
    func build(for workout: HealthWorkout) -> HealthWorkoutDetailView {
        let viewModel = HealthWorkoutDetailViewModel(
            workout: workout,
            healthUseCase: HealthContainer().makeUseCase(),
            trainingUseCase: TrainingContainer().makeUseCase()
        )
        return HealthWorkoutDetailView(viewModel: viewModel)
    }
}
