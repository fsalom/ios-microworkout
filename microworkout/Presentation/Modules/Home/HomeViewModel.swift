import Foundation
import SwiftUICore

struct HomeUiState {
    var weeks: [[HealthDay]]
    var trainings: [Training] = []
    var error: String?
    var healthInfoForToday: HealthDay = HealthDay(date: Date())
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
                let healthInfoForToday = try await healthUseCase.getHealthInfoForToday()
                await MainActor.run {
                    self.uiState.weeks = weeks
                    self.uiState.healthInfoForToday = healthInfoForToday
                }
            } catch {
                await MainActor.run {
                    self.uiState.error = "Se ha producido un error obteniendo la información de salud"
                }
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
            DispatchQueue.main.async {
                self.uiState.isHealthKitAuthorized = authorization
            }
        }
    }

    func goToTrainings() {
        router.goToWorkoutList()
    }

    func goToStart(this training: Training, and namespace: Namespace.ID) {
        router.goToStart(this: training, and: namespace)
    }


}
