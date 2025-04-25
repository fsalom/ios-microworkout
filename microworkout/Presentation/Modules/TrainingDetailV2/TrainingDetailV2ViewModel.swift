import Foundation
import SwiftUI

struct TrainingDetailUIState {
    var currentTraining: Training?
    var hasTrainingStarted: Bool = false
}

final class TrainingDetailV2ViewModel: ObservableObject {
    var appState: AppState
    private var router: TrainingDetailV2Router
    private var trainingUseCase: TrainingUseCase
    @Published var training: Training
    @Published var uiState: TrainingDetailUIState = .init()

    init(trainingUseCase: TrainingUseCase,
         router: TrainingDetailV2Router,
         training: Training,
         appState: AppState) {
        self.trainingUseCase = trainingUseCase
        self.router = router
        self.appState = appState
        self.training = training
    }

    func startTraining() {
        DispatchQueue.main.async {
            self.training.startedAt = Date()
            self.training.sets.append(Date())
            self.trainingUseCase.saveCurrent(self.training)
            self.router.goBack()
            self.appState.changeScreen(to: .workout(training: self.training))
        }
    }
}
