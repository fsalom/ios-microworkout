import Foundation
import SwiftUICore

struct HomeUiState {
    var weeks: [[HealthDay]]
    var trainings: [Training] = []
    var error: String?
    var isHealthKitAuthorized: Bool = false
}

final class HomeViewModel: ObservableObject {
    @Published var uiState: HomeUiState = .init(weeks: [[]], error: nil)

    private var router: HomeRouter
    private var healthKitManager: HealthKitManager!
    private var currentTraining: Training = Training.mock()
    private var trainingUseCase: TrainingUseCase
    private var healthUseCase: HealthUseCase

    init(router: HomeRouter,
         trainingUseCase: TrainingUseCase,
         healthUseCase: HealthUseCase,
         healthKitManager: HealthKitManager) {
        self.router = router
        self.trainingUseCase = trainingUseCase
        self.healthUseCase = healthUseCase
        self.healthKitManager = healthKitManager
        self.loadTrainings()
        self.askForPermissions()
    }

    func save(this training: Training) {
        trainingUseCase.save(training)
    }

    func loadWeeksWithHealthInfo() {
        Task {
            do {
                let weeks = try await healthUseCase.getDaysPerWeeksWithHealthInfo(for: 4)
                await MainActor.run {
                    self.uiState.weeks = weeks
                }
            } catch {

            }
        }
    }

    private func loadTrainings() {
        Task {
            await MainActor.run {
                self.uiState.trainings = trainingUseCase.getTrainings()
            }
        }
    }

    private func askForPermissions() {
        healthKitManager.requestAuthorization { authorization, error in
            self.uiState.isHealthKitAuthorized = authorization
        }
    }

    func goToTrainings() {
        router.goToWorkoutList()
    }

    func goToStart(this training: Training, and namespace: Namespace.ID) {
        router.goToStart(this: training, and: namespace)
    }


}
