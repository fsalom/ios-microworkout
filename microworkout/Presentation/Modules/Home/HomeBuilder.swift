class HomeBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(appState: AppState) -> HomeView {
        let viewModel = HomeViewModel(
            router: HomeRouter(navigator: Navigator.shared, component: component),
            trainingUseCase: TrainingContainer(component: component).makeUseCase(),
            healthUseCase: HealthContainer(component: component).makeUseCase(),
            workoutEntryUseCase: WorkoutEntryContainer(component: component).makeUseCase(),
            mealUseCase: MealContainer(component: component).makeUseCase(),
            userProfileUseCase: UserProfileContainer(component: component).makeUseCase(),
            appState: appState)
        return HomeView(viewModel: viewModel)
    }
}
