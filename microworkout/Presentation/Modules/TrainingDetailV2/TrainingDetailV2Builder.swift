import SwiftUI

class TrainingDetailV2Builder {
    func build(this training: Training, and namespace: Namespace.ID) -> TrainingDetailV2View {
        let router = TrainingDetailV2Router(navigator: Navigator.shared)
        let viewModel = TrainingDetailV2ViewModel(router: router, training: training, namespace: namespace)
        return TrainingDetailV2View(viewModel: viewModel)
    }
}
