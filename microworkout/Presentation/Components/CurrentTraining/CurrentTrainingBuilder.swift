class CurrentTrainingBuilder {
    func build(appState: AppState) -> CurrentTrainingView {
        let viewModel = CurrentTrainingViewModel(appState: appState)
        return CurrentTrainingView(viewModel: viewModel)
    }
}
