class CurrentSessionBuilder {
    func build() -> CurrentSessionView {
        let viewModel = CurrentSessionViewModel(
            exerciseUseCase: ExerciseContainer().makeUseCase(),
            workoutEntryUseCase: WorkoutEntryContainer().makeUseCase(),
            healthUseCase: HealthContainer().makeUseCase(),
            trainingUseCase: TrainingContainer().makeUseCase()
        )
        return CurrentSessionView(viewModel: viewModel)
    }
}
