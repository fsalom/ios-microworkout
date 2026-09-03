class ProfileBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> ProfileView {
        let viewModel = ProfileViewModel(
            router: ProfileRouter(navigator: Navigator.shared, component: component),
            adaptiveTDEEUseCase: component.adaptiveTDEEUseCase,
            coachBriefsUseCase: component.coachBriefsUseCase,
            userProfileUseCase: component.userProfileUseCase,
            healthUseCase: component.healthUseCase,
            authService: component.authService,
            syncLocalDataUseCase: component.syncLocalDataUseCase
        )
        return ProfileView(viewModel: viewModel)
    }
}
