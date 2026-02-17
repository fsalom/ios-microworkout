import SwiftUI
import Combine

struct ProfileUiState {
    var name: String = ""
    var weight: Double = 70
    var height: Double = 170
    var age: Int = 30
    var gender: UserProfile.Gender = .male
    var activityLevel: UserProfile.ActivityLevel = .moderate
    var fitnessGoal: UserProfile.FitnessGoal = .maintain
    var macroProfile: UserProfile.MacroProfile = .balanced
    var hasProfile: Bool = false
    var dailyCalorieTarget: Double = 0
    var macroTargets: NutritionInfo = .zero
    var isEditing: Bool = false
    var freeDays: Set<Int> = []
    var freeDayExtraCalories: Double = 500
    var hasCycling: Bool = false
    var strictDayCalorieTarget: Double = 0
    var freeDayCalorieTarget: Double = 0
    var healthKitStatus: HealthAuthorizationStatus = .notDetermined
    var isHealthDataAvailable: Bool = false
}

class ProfileViewModel: ObservableObject {
    @Published var uiState: ProfileUiState = .init()

    private var userProfileUseCase: UserProfileUseCaseProtocol
    private var healthUseCase: HealthUseCaseProtocol

    init(userProfileUseCase: UserProfileUseCaseProtocol,
         healthUseCase: HealthUseCaseProtocol) {
        self.userProfileUseCase = userProfileUseCase
        self.healthUseCase = healthUseCase
        loadProfile()
        loadHealthKitStatus()
    }

    func loadProfile() {
        guard let profile = userProfileUseCase.getProfile() else { return }
        uiState.name = profile.name
        uiState.weight = profile.weight
        uiState.height = profile.height
        uiState.age = profile.age
        uiState.gender = profile.gender
        uiState.activityLevel = profile.activityLevel
        uiState.fitnessGoal = profile.resolvedGoal
        uiState.macroProfile = profile.resolvedMacroProfile
        uiState.hasProfile = true
        uiState.dailyCalorieTarget = profile.dailyCalorieTarget
        uiState.macroTargets = profile.macroTargets
        uiState.freeDays = profile.resolvedFreeDays
        uiState.freeDayExtraCalories = profile.resolvedFreeDayExtra
        uiState.hasCycling = profile.hasCycling
        uiState.strictDayCalorieTarget = profile.strictDayCalorieTarget
        uiState.freeDayCalorieTarget = profile.freeDayCalorieTarget
    }

    func startEditing() {
        uiState.isEditing = true
    }

    func cancelEditing() {
        loadProfile()
        uiState.isEditing = false
    }

    func save() {
        let profile = UserProfile(
            name: uiState.name.isEmpty ? "Usuario" : uiState.name,
            height: uiState.height,
            weight: uiState.weight,
            age: uiState.age,
            gender: uiState.gender,
            activityLevel: uiState.activityLevel,
            fitnessGoal: uiState.fitnessGoal,
            macroProfile: uiState.macroProfile,
            freeDays: uiState.freeDays.isEmpty ? nil : Array(uiState.freeDays),
            freeDayExtraCalories: uiState.freeDays.isEmpty ? nil : uiState.freeDayExtraCalories
        )
        userProfileUseCase.saveProfile(profile)
        userProfileUseCase.setOnboardingCompleted(true)
        uiState.hasProfile = true
        uiState.dailyCalorieTarget = profile.dailyCalorieTarget
        uiState.macroTargets = profile.macroTargets
        uiState.hasCycling = profile.hasCycling
        uiState.strictDayCalorieTarget = profile.strictDayCalorieTarget
        uiState.freeDayCalorieTarget = profile.freeDayCalorieTarget
        uiState.isEditing = false
    }

    // MARK: - HealthKit

    func loadHealthKitStatus() {
        uiState.isHealthDataAvailable = healthUseCase.isHealthDataAvailable
        uiState.healthKitStatus = healthUseCase.authorizationStatus
    }

    func requestHealthKit() {
        Task { @MainActor in
            _ = try? await healthUseCase.requestAuthorization()
            loadHealthKitStatus()
        }
    }

    func openHealthApp() {
        guard let url = URL(string: "x-apple-health://") else { return }
        UIApplication.shared.open(url)
    }
}
