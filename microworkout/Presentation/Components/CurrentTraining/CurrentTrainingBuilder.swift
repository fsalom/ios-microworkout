class CurrentTrainingBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(appState: AppState) -> CurrentTrainingView {
        let useCase = TrainingContainer(component: component).makeUseCase()
        let viewModel = CurrentTrainingViewModel(appState: appState, useCase: useCase)
        return CurrentTrainingView(viewModel: viewModel)
    }
}
