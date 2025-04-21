import Foundation
import SwiftUICore

struct HomeUiState {
    var weeks: [[HealthDay]]
    var trainings: [Training] = []
    var currentTraining: Training?
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
    private var appState: AppState

    init(router: HomeRouter,
         trainingUseCase: TrainingUseCase,
         healthUseCase: HealthUseCase,
         healthKitManager: HealthKitManager,
         appState: AppState) {
        self.router = router
        self.trainingUseCase = trainingUseCase
        self.healthUseCase = healthUseCase
        self.healthKitManager = healthKitManager
        self.appState = appState
        self.loadTrainings()
        self.askForPermissions()
        if let training = self.trainingUseCase.getCurrentTraining() {
            appState.changeScreen(to: .workout(training: training))
        }
    }

    func save(this training: Training) {
        trainingUseCase.save(training)
    }

    func showHealthInfo(for day: HealthDay) {
        DispatchQueue.main.async {
            self.uiState.healthInfoForToday = day
        }
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
                self.uiState.currentTraining = trainingUseCase.getCurrentTraining()
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

    func goToStart(this training: Training) {
        //appState.changeScreen(to: .workout(training: training))
        router.goToStart(this: training, and: appState)
    }


}
