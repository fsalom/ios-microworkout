
class ProfileBuilder {
    func build() -> ProfileView {
        let viewModel = ProfileViewModel(exerciseUseCase: ExerciseContainer().makeUseCase(),
                                         loggedExerciseUseCase: LoggedExerciseContainer().makeUseCase())
        return ProfileView(viewModel: viewModel)
    }
}
