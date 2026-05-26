class ProfileBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> ProfileView {
        let viewModel = ProfileViewModel(
            userProfileUseCase: component.userProfileUseCase,
            healthUseCase: component.healthUseCase,
            authService: component.authService
        )
        return ProfileView(viewModel: viewModel, component: component)
    }
}
