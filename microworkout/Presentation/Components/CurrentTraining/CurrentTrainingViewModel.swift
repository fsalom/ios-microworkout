import Foundation

struct CurrentTrainingUIState {
    var training: Training
    var hasToResetTimer: Bool = false
}

class CurrentTrainingViewModel: ObservableObject {
    @Published var uiState: CurrentTrainingUIState = .init(training: Training.mock())
    private var useCase: TrainingUseCaseProtocol
    private var appState: AppState

    init(appState: AppState, useCase: TrainingUseCaseProtocol) {
        self.appState = appState
        self.useCase = useCase
        self.uiState.training = Training.mock()
        self.uiState.training.startedAt = Date()
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let training = try? await self.useCase.getCurrent() {
                self.uiState.training = training
                self.uiState.training.startedAt = Date()
            } else {
                assertionFailure("No current training available")
            }
        }
    }

    func incrementSet() {
        self.uiState.training.sets.append(Date())
        self.uiState.hasToResetTimer = true
        self.uiState.training.calculateNumberOfSeconds()
        let snapshot = self.uiState.training
        Task { try? await self.useCase.saveCurrent(snapshot) }
    }

    func getTotalReps() -> Int {
        self.uiState.training.numberOfReps * self.uiState.training.numberOfSets
    }

    func getTotalDurationInHours() -> Int {
        let numberOfminutesPerSet = self.uiState.training.numberOfMinutesPerSet
        let numberOfSets = self.uiState.training.numberOfSets
        return (numberOfminutesPerSet * numberOfSets) / 60
    }

    func getCurrentSets() -> Int {
        return self.uiState.training.sets.count
    }

    func getCurrentTotalReps() -> Int {
        self.uiState.training.numberOfReps * self.getCurrentSets()
    }

    func saveAndClose() {
        Task { @MainActor in
            try? await self.useCase.finish(self.uiState.training)
            self.appState.changeScreen(to: .home)
        }
    }
}
