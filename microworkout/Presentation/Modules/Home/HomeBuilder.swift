class HomeBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(appState: AppState) -> HomeView {
        let viewModel = HomeViewModel(
            router: HomeRouter(navigator: Navigator.shared, component: component),
            trainingUseCase: component.trainingUseCase,
            healthUseCase: component.healthUseCase,
            workoutEntryUseCase: component.workoutEntryUseCase,
            mealUseCase: component.mealUseCase,
            userProfileUseCase: component.userProfileUseCase,
            coachUseCase: component.coachUseCase,
            appState: appState)
        return HomeView(viewModel: viewModel)
    }
}
