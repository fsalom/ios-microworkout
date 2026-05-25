class CurrentSessionBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> CurrentSessionView {
        let viewModel = CurrentSessionViewModel(
            exerciseUseCase: component.exerciseUseCase,
            workoutEntryUseCase: component.workoutEntryUseCase,
            healthUseCase: component.healthUseCase,
            trainingUseCase: component.trainingUseCase
        )
        return CurrentSessionView(viewModel: viewModel)
    }
}
