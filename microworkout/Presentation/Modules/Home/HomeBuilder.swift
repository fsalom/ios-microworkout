
class HomeBuilder {
    func build(appState: AppState) -> HomeView {
        let viewModel = HomeViewModel(
            router: HomeRouter(navigator: Navigator.shared),
            trainingUseCase: TrainingContainer().makeUseCase(),
            healthUseCase: HealthContainer().makeUseCase(),
            loggedExerciseUseCase: LoggedExerciseContainer().makeUseCase(),
            healthKitManager: HealthKitManager.shared,
            appState: appState)
        return HomeView(viewModel: viewModel)
    }
}
