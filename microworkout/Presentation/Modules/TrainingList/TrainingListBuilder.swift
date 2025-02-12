class TrainingListBuilder {
    func build() -> TrainingListView {
        let viewModel = TrainingListViewModel(router: TrainingListRouter(navigator: Navigator.shared))
        return TrainingListView(viewModel: viewModel)
    }
}
