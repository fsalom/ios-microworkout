import SwiftUI

class TrainingDetailV2Builder {
    func build(this training: Training, and appState: AppState) -> TrainingDetailV2View {
        let router = TrainingDetailV2Router(navigator: Navigator.shared)
        let viewModel = TrainingDetailV2ViewModel(
            trainingUseCase: TrainingContainer().makeUseCase(),
            router: router,
            training: training,
            appState: appState)
        return TrainingDetailV2View(viewModel: viewModel)
    }
}
