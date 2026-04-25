class TrainingListV2Builder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> TrainingListV2View {
        let viewModel = TrainingListV2ViewModel(router: TrainingListV2Router(navigator: Navigator.shared))
        return TrainingListV2View(viewModel: viewModel)
    }
}
