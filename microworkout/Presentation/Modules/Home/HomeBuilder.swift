
class HomeBuilder {
    func build() -> HomeView {
        let viewModel = HomeViewModel(
            router: HomeRouter(navigator: Navigator.shared),
            trainingUseCase: TrainingContainer().makeUseCase(),
            healthKitManager: HealthKitManager.shared)
        return HomeView(viewModel: viewModel)
    }
}
