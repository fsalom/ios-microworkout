import Foundation
import SwiftUI

struct HomeUiState {
    var weeks: [[HealthDay]]
    var trainings: [Training] = []
    var lastTrainings: [Training] = []
    var lastEntriesByDay: [WorkoutEntryByDay] = []
    var lastWorkoutItems: [WorkoutItem] = []
    var currentTraining: Training?
    var error: String?
    var healthInfoForToday: HealthDay = HealthDay(date: Date())
    var isHealthKitAuthorized: Bool = false
    var todayCalories: Double = 0
    var todayNutrition: NutritionInfo = .zero
    var dailyCalorieTarget: Double? = nil
    var macroTargets: NutritionInfo? = nil
    var userName: String? = nil
    var todayIsFreeDay: Bool = false
    var hasCycling: Bool = false
}

final class HomeViewModel: ObservableObject {
    @Published var uiState: HomeUiState = .init(weeks: [[]], error: nil)
    private var router: HomeRouter
    private var healthKitManager: HealthKitManager!
    private var currentTraining: Training = Training.mock()
    private var trainingUseCase: TrainingUseCase
    private var healthUseCase: HealthUseCase
    private var workoutEntryUseCase: WorkoutEntryUseCaseProtocol
    private var mealUseCase: MealUseCaseProtocol
    private var userProfileUseCase: UserProfileUseCaseProtocol
    private var appState: AppState

    init(router: HomeRouter,
         trainingUseCase: TrainingUseCase,
         healthUseCase: HealthUseCase,
         workoutEntryUseCase: WorkoutEntryUseCaseProtocol,
         mealUseCase: MealUseCaseProtocol,
         userProfileUseCase: UserProfileUseCaseProtocol,
         healthKitManager: HealthKitManager,
         appState: AppState) {
        self.router = router
        self.trainingUseCase = trainingUseCase
        self.healthUseCase = healthUseCase
        self.workoutEntryUseCase = workoutEntryUseCase
        self.mealUseCase = mealUseCase
        self.userProfileUseCase = userProfileUseCase
        self.healthKitManager = healthKitManager
        self.appState = appState
        self.load()
        self.askForPermissions()
        if let training = self.trainingUseCase.getCurrent() {
            appState.changeScreen(to: .workout(training: training))
        }
    }

    func load() {
        self.loadTrainings()
        self.loadLastTrainings()
        self.loadAllWorkouts()
        self.loadCalorieData()
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

    private func loadAllWorkouts() {
        Task { @MainActor in
            let entries = try await workoutEntryUseCase.getAllByDay()
            self.uiState.lastEntriesByDay = entries

            var items: [WorkoutItem] = entries.map { .manual($0) }

            if let awWorkouts = try? await healthUseCase.getRecentWorkouts() {
                items += awWorkouts.map { .appleWatch($0) }
            }

            items.sort { $0.sortDate > $1.sortDate }
            self.uiState.lastWorkoutItems = items
        }
    }

    private func loadCalorieData() {
        Task { @MainActor in
            let profile = userProfileUseCase.getProfile()
            self.uiState.dailyCalorieTarget = profile?.todayCalorieTarget
            self.uiState.macroTargets = profile?.todayMacroTargets
            self.uiState.userName = profile?.name
            self.uiState.todayIsFreeDay = profile?.todayIsFreeDay ?? false
            self.uiState.hasCycling = profile?.hasCycling ?? false
            if let totals = try? await mealUseCase.getTodayTotals() {
                self.uiState.todayCalories = totals.calories
                self.uiState.todayNutrition = totals
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

    func goTo(this entryDay: WorkoutEntryByDay) {
        router.goTo(this: entryDay)
    }

    func goToStart(this training: Training) {
        router.goToStart(this: training, and: appState)
    }

    func goTo(this healthWorkout: HealthWorkout) {
        router.goToHealthWorkoutDetail(healthWorkout)
    }
}
