class CurrentSessionBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> CurrentSessionView {
        let viewModel = CurrentSessionViewModel(
            exerciseUseCase: ExerciseContainer(component: component).makeUseCase(),
            workoutEntryUseCase: WorkoutEntryContainer(component: component).makeUseCase(),
            healthUseCase: HealthContainer(component: component).makeUseCase(),
            trainingUseCase: TrainingContainer(component: component).makeUseCase()
        )
        return CurrentSessionView(viewModel: viewModel)
    }
}
