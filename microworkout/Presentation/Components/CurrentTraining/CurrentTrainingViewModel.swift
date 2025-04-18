import Foundation

struct CurrentTrainingUIState {
    var training: Training
    var hasToResetTimer: Bool = false
}

class CurrentTrainingViewModel: ObservableObject {
    @Published var uiState: CurrentTrainingUIState = .init(training: Training.mock())
    private var useCase: TrainingUseCase = TrainingContainer().makeUseCase()
    private var appState: AppState

    init(appState: AppState) {
        self.appState = appState
        guard let training = self.useCase.getCurrentTraining() else {
            fatalError()
        }
        self.uiState.training = training
    }

    func incrementSet() {
        self.uiState.training.sets.append(Date())
        self.uiState.hasToResetTimer = true
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

    func currentDurationInMinutes() -> Int {
        let dates = self.uiState.training.sets
        guard dates.count > 1 else { return 0 }

        let sortedDates = dates.sorted()
        var totalMinutes = 0

        for i in 1..<sortedDates.count {
            let previous = sortedDates[i - 1]
            let current = sortedDates[i]
            let interval = current.timeIntervalSince(previous)
            totalMinutes += Int(interval / 60)
        }

        return totalMinutes
    }
    
}
