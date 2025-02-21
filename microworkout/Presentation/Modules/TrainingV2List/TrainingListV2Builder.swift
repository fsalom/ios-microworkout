class TrainingListV2Builder {
    func build() -> TrainingListV2View {
        let viewModel = TrainingListV2ViewModel(router: TrainingListV2Router(navigator: Navigator.shared))
        return TrainingListV2View(viewModel: viewModel)
    }
}
