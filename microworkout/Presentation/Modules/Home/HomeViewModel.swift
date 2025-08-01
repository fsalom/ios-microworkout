import Foundation
import SwiftUICore

struct HomeUiState {
    var weeks: [[HealthDay]]
    var trainings: [Training] = []
    var lastTrainings: [Training] = []
    var lastLoggedExercises: [LoggedExerciseByDay] = []
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
    private var loggedExerciseUseCase: LoggedExerciseUseCase
    private var appState: AppState

    init(router: HomeRouter,
         trainingUseCase: TrainingUseCase,
         healthUseCase: HealthUseCase,
         loggedExerciseUseCase: LoggedExerciseUseCase,
         healthKitManager: HealthKitManager,
         appState: AppState) {
        self.router = router
        self.trainingUseCase = trainingUseCase
        self.healthUseCase = healthUseCase
        self.loggedExerciseUseCase = loggedExerciseUseCase
        self.healthKitManager = healthKitManager
        self.appState = appState
        self.loadTrainings()
        self.loadLastTrainings()
        self.loadLoggedExercises()
        self.askForPermissions()
        if let training = self.trainingUseCase.getCurrent() {
            appState.changeScreen(to: .workout(training: training))
        }
    }

    func save(this training: Training) {
        trainingUseCase.saveCurrent(training)
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
                self.uiState.currentTraining = trainingUseCase.getCurrent()
            }
        }
    }

    private func loadLastTrainings() {
        Task {
            await MainActor.run {
                self.uiState.lastTrainings = trainingUseCase.getFinished()
            }
        }
    }

    private func loadLoggedExercises() {
        Task { @MainActor in
            let lastLoggedExercises = try await loggedExerciseUseCase.getAll()
            self.uiState.lastLoggedExercises = lastLoggedExercises
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
        router.goToStart(this: training, and: appState)
    }
}
