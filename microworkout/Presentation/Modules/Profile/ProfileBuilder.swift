
class ProfileBuilder {
    func build() -> ProfileView {
        let viewModel = ProfileViewModel(
            exerciseUseCase: ExerciseContainer().makeUseCase(),
            workoutEntryUseCase: WorkoutEntryContainer().makeUseCase()
        )
        return ProfileView(viewModel: viewModel)
    }
}
