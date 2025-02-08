class TrainingListBuilder {
    func build() -> TrainingListView {
        let viewModel = TrainingListViewModel()
        return TrainingListView(viewModel: viewModel)
    }
}
