class ProfileBuilder {
    func build() -> ProfileView {
        let viewModel = ProfileViewModel(
            userProfileUseCase: UserProfileContainer().makeUseCase()
        )
        return ProfileView(viewModel: viewModel)
    }
}
