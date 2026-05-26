import SwiftUI
import Combine
import AuthenticationServices

struct ProfileUiState {
    var authError: String?
    var isSigningIn: Bool = false
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
    private let authService: AuthServiceProtocol

    init(userProfileUseCase: UserProfileUseCaseProtocol,
         healthUseCase: HealthUseCaseProtocol,
         authService: AuthServiceProtocol) {
        self.userProfileUseCase = userProfileUseCase
        self.healthUseCase = healthUseCase
        self.authService = authService
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

    // MARK: - Authentication

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            uiState.authError = error.localizedDescription
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let codeData = credential.authorizationCode,
                let code = String(data: codeData, encoding: .utf8)
            else {
                uiState.authError = "No se obtuvo código de autorización de Apple"
                return
            }
            Task { @MainActor in
                uiState.isSigningIn = true
                defer { uiState.isSigningIn = false }
                do {
                    try await authService.signInWithApple(authCode: code)
                } catch {
                    uiState.authError = error.localizedDescription
                }
            }
        }
    }

    func signOut() {
        Task { @MainActor in
            await authService.logout()
        }
    }

    func dismissAuthError() {
        uiState.authError = nil
    }
}
