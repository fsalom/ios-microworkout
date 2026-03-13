class ProfileBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> ProfileView {
        let viewModel = ProfileViewModel(
            userProfileUseCase: UserProfileContainer(component: component).makeUseCase(),
            healthUseCase: HealthContainer(component: component).makeUseCase()
        )
        return ProfileView(viewModel: viewModel)
    }
}
