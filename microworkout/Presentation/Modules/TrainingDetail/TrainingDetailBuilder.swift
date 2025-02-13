class TrainingDetailBuilder {
    func build() -> TrainingDetailView {
        let router = TrainingDetailRouter(navigator: Navigator.shared)
        let viewModel = TrainingDetailViewModel(router: router)
        return TrainingDetailView(viewModel: viewModel)
    }
}
