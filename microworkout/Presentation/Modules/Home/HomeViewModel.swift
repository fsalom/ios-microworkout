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
    var isLoadingCalories: Bool = true
    var isLoadingHealth: Bool = true
    var caloriesBurnedToday: Double = 0
    var workoutsCountToday: Int = 0
    var todayHealthWorkouts: [HealthWorkout] = []
    var mealsByType: [MealType: [Meal]] = [:]
    var coachInsight: CoachInsight? = nil
    var isLoadingCoach: Bool = false
}

final class HomeViewModel: ObservableObject {
    @Published var uiState: HomeUiState = .init(weeks: [[]], error: nil)
    private var router: HomeRouter
    private var currentTraining: Training = Training.mock()
    private var trainingUseCase: TrainingUseCaseProtocol
    private var healthUseCase: HealthUseCaseProtocol
    private var workoutEntryUseCase: WorkoutEntryUseCaseProtocol
    private var mealUseCase: MealUseCaseProtocol
    private var userProfileUseCase: UserProfileUseCaseProtocol
    private var coachUseCase: CoachUseCaseProtocol
    private var appState: AppState

    init(router: HomeRouter,
         trainingUseCase: TrainingUseCaseProtocol,
         healthUseCase: HealthUseCaseProtocol,
         workoutEntryUseCase: WorkoutEntryUseCaseProtocol,
         mealUseCase: MealUseCaseProtocol,
         userProfileUseCase: UserProfileUseCaseProtocol,
         coachUseCase: CoachUseCaseProtocol,
         appState: AppState) {
        self.router = router
        self.trainingUseCase = trainingUseCase
        self.healthUseCase = healthUseCase
        self.workoutEntryUseCase = workoutEntryUseCase
        self.mealUseCase = mealUseCase
        self.userProfileUseCase = userProfileUseCase
        self.coachUseCase = coachUseCase
        self.appState = appState
    }

    /// Acciones de arranque (datos + permisos + posible salto a workout en curso).
    /// Llámese desde `.onAppear` de la View; antes vivía en el init y arrancaba
    /// efectos en cadena (navegación) antes de que la pantalla estuviera viva.
    func start() {
        self.load()
        self.askForPermissions()
        Task { @MainActor in
            if let training = try? await self.trainingUseCase.getCurrent() {
                appState.changeScreen(to: .workout(training: training))
            }
        }
    }

    func load() {
        self.loadTrainings()
        self.loadLastTrainings()
        self.loadAllWorkouts()
        self.loadCalorieData()
        self.loadCoachInsight()
    }

    private func loadCoachInsight() {
        uiState.isLoadingCoach = true
        Task { @MainActor in
            let insight = await coachUseCase.homeInsight()
            self.uiState.coachInsight = insight
            self.uiState.isLoadingCoach = false
        }
    }

    func save(this training: Training) {
        Task { try? await trainingUseCase.saveCurrent(training) }
    }

    func showHealthInfo(for day: HealthDay) {
        Task { @MainActor in
            self.uiState.healthInfoForToday = day
        }
    }

    func loadWeeksWithHealthInfo() {
        Task {
            do {
                let weeks = try await healthUseCase.getDaysPerWeeksWithHealthInfo(for: 1)
                let healthInfoForToday = try await healthUseCase.getHealthInfoForToday()
                await MainActor.run {
                    self.uiState.weeks = weeks
                    self.uiState.healthInfoForToday = healthInfoForToday
                    self.uiState.isLoadingHealth = false
                }
            } catch {
                await MainActor.run {
                    self.uiState.error = "Se ha producido un error obteniendo la información de salud"
                    self.uiState.isLoadingHealth = false
                }
            }
        }
    }

    private func loadTrainings() {
        Task { @MainActor in
            let trainings = (try? await trainingUseCase.getTrainings()) ?? []
            let current = try? await trainingUseCase.getCurrent()
            self.uiState.trainings = trainings
            self.uiState.currentTraining = current
        }
    }

    private func loadLastTrainings() {
        Task { @MainActor in
            self.uiState.lastTrainings = (try? await trainingUseCase.getFinished()) ?? []
        }
    }

    private func loadAllWorkouts() {
        Task { @MainActor in
            let entries = try await workoutEntryUseCase.getAllByDay()
            self.uiState.lastEntriesByDay = entries

            var items: [WorkoutItem] = entries.map { .manual($0) }

            let awWorkouts = (try? await healthUseCase.getRecentWorkouts()) ?? []
            items += awWorkouts.map { .appleWatch($0) }

            items.sort { $0.sortDate > $1.sortDate }
            self.uiState.lastWorkoutItems = items

            // Today's burned calories from Apple Watch workouts
            let cal = Calendar.current
            let todayWorkouts = awWorkouts
                .filter { cal.isDateInToday($0.startDate) }
                .sorted { $0.startDate > $1.startDate }
            self.uiState.caloriesBurnedToday = todayWorkouts.reduce(0) { $0 + ($1.totalCalories ?? 0) }
            self.uiState.workoutsCountToday = todayWorkouts.count
            self.uiState.todayHealthWorkouts = todayWorkouts
        }
    }

    private func loadCalorieData() {
        Task { @MainActor in
            let profile = try? await userProfileUseCase.getProfile()
            self.uiState.dailyCalorieTarget = profile?.todayCalorieTarget
            self.uiState.macroTargets = profile?.todayMacroTargets
            self.uiState.userName = profile?.name
            self.uiState.todayIsFreeDay = profile?.todayIsFreeDay ?? false
            self.uiState.hasCycling = profile?.hasCycling ?? false
            if let meals = try? await mealUseCase.getMealsForToday() {
                let totals = meals.reduce(NutritionInfo.zero) { $0 + $1.totalNutrition }
                self.uiState.todayCalories = totals.calories
                self.uiState.todayNutrition = totals
                self.uiState.mealsByType = Dictionary(grouping: meals, by: { $0.type })
            }
            self.uiState.isLoadingCalories = false
        }
    }

    private func askForPermissions() {
        Task { @MainActor in
            let authorized = (try? await healthUseCase.requestAuthorization()) ?? false
            self.uiState.isHealthKitAuthorized = authorized
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

    func goToAddMeal() {
        router.goToAddMeal()
    }

    func goToChat(prompt: String) {
        router.goToChat(prompt: prompt)
    }
}
