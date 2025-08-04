

class CurrentSessionBuilder {
    func build() -> CurrentSessionView {
        let viewModel = CurrentSessionViewModel(exerciseUseCase: ExerciseContainer().makeUseCase(),
                                                loggedExerciseUseCase: LoggedExerciseContainer().makeUseCase())
        return CurrentSessionView(viewModel: viewModel)
    }
}
