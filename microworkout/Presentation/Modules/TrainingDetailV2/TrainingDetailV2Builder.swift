import SwiftUI

class TrainingDetailV2Builder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(this training: Training, and appState: AppState) -> TrainingDetailV2View {
        let router = TrainingDetailV2Router(navigator: Navigator.shared)
        let viewModel = TrainingDetailV2ViewModel(
            trainingUseCase: component.trainingUseCase,
            router: router,
            training: training,
            appState: appState)
        return TrainingDetailV2View(viewModel: viewModel)
    }
}
