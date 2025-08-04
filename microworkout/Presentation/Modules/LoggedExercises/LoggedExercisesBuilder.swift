
class LoggedExercisesBuilder {
    func build(this loggedExercises: LoggedExerciseByDay) -> LoggedExercisesView {
        let viewModel = LoggedExercisesViewModel(
            router: HomeRouter(navigator: Navigator.shared),
            loggedExerciseUseCase: LoggedExerciseContainer().makeUseCase(),
            loggedExercises: loggedExercises)
        return LoggedExercisesView(viewModel: viewModel)
    }
}
