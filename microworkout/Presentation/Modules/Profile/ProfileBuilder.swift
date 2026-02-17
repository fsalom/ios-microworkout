class ProfileBuilder {
    func build() -> ProfileView {
        let viewModel = ProfileViewModel(
            userProfileUseCase: UserProfileContainer().makeUseCase(),
            healthUseCase: HealthContainer().makeUseCase()
        )
        return ProfileView(viewModel: viewModel)
    }
}
