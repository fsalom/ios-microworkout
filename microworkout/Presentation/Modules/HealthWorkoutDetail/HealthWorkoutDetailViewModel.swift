import Foundation

struct HealthWorkoutDetailUiState {
    var workout: HealthWorkout
    var availableTrainings: [Training] = []
    var linkedTraining: Training? = nil
}

final class HealthWorkoutDetailViewModel: ObservableObject {
    @Published var uiState: HealthWorkoutDetailUiState

    private var healthUseCase: HealthUseCaseProtocol
    private var trainingUseCase: TrainingUseCase

    init(workout: HealthWorkout,
         healthUseCase: HealthUseCaseProtocol,
         trainingUseCase: TrainingUseCase) {
        self.healthUseCase = healthUseCase
        self.trainingUseCase = trainingUseCase
        self.uiState = HealthWorkoutDetailUiState(workout: workout)
        loadTrainings()
    }

    private func loadTrainings() {
        let trainings = trainingUseCase.getTrainings()
        uiState.availableTrainings = trainings
        if let linkedID = uiState.workout.linkedTrainingID {
            uiState.linkedTraining = trainings.first { $0.id == linkedID }
        }
    }

    func linkTo(training: Training) {
        healthUseCase.linkWorkout(uiState.workout.id, to: training.id)
        uiState.workout.linkedTrainingID = training.id
        uiState.linkedTraining = training
    }

    func unlinkTraining() {
        healthUseCase.unlinkWorkout(uiState.workout.id)
        uiState.workout.linkedTrainingID = nil
        uiState.linkedTraining = nil
    }
}
