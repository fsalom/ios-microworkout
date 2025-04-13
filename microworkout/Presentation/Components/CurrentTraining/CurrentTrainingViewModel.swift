import Foundation

class CurrentTrainingViewModel: ObservableObject {
    @Published var training: Training
    @Published var hasToResetTimer = false
    private var useCase: TrainingUseCase

    init(useCase: TrainingUseCase) {
        self.useCase = useCase
        guard let training = self.useCase.getCurrentTraining() else {
            fatalError()
        }
        self.training = training
    }

    func incrementSet() {
        training.numberOfSetsCompleted += 1
        training.sets.append(Date())  // o la lógica real que uses
        hasToResetTimer = true
    }

    func totalReps() -> Int {
        training.numberOfReps * training.numberOfSets
    }

    func totalDurationInHours() -> Int {
        (training.numberOfMinutesPerSet * training.numberOfSets) / 60
    }
}
