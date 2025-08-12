class CurrentSessionBuilder {
    func build() -> CurrentSessionView {
        let viewModel = CurrentSessionViewModel(
            exerciseUseCase: ExerciseContainer().makeUseCase(),
            workoutEntryUseCase: WorkoutEntryContainer().makeUseCase()
        )
        return CurrentSessionView(viewModel: viewModel)
    }
}
