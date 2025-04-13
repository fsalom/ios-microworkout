import Foundation
import SwiftUI

struct TrainingDetailUIState {
    var currentTraining: Training?
    var hasTrainingStarted: Bool = false
}

final class TrainingDetailV2ViewModel: ObservableObject {

    var namespace: Namespace.ID
    private var router: TrainingDetailV2Router
    private var trainingUseCase: TrainingUseCase
    @Published var training: Training
    @Published var uiState: TrainingDetailUIState = .init()

    init(trainingUseCase: TrainingUseCase,
         router: TrainingDetailV2Router,
         training: Training,
         namespace: Namespace.ID) {
        self.trainingUseCase = trainingUseCase
        self.router = router
        self.namespace = namespace
        self.training = training
    }

    func startTraining() {
        DispatchQueue.main.async {
            self.trainingUseCase.save(self.training)
            self.uiState.hasTrainingStarted = true
            self.uiState.currentTraining = self.training
        }
    }
}
