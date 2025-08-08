
class LoggedExercisesBuilder {
    func build(this loggedExercises: LoggedExerciseByDay) -> LoggedExercisesView {
        let viewModel = LoggedExercisesViewModel(
            router: LoggedExercisesRouter(navigator: Navigator.shared),
            loggedExerciseUseCase: LoggedExerciseContainer().makeUseCase(),
            loggedExercises: loggedExercises)
        return LoggedExercisesView(viewModel: viewModel)
    }
}
