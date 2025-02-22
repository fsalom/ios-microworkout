import SwiftUI

class TrainingDetailBuilder {
    func build(this training: Training, and namespace: Namespace.ID) -> TrainingDetailView {
        let router = TrainingDetailRouter(navigator: Navigator.shared)
        let viewModel = TrainingDetailViewModel(router: router, training: training, namespace: namespace)
        return TrainingDetailView(viewModel: viewModel)
    }
}
