import Foundation
import Combine

struct OnboardingUiState {
    var currentStep: Int = 0
    var name: String = ""
    var weight: Double = 70
    var height: Double = 170
    var age: Int = 30
    var gender: UserProfile.Gender = .male
    var activityLevel: UserProfile.ActivityLevel = .moderate
    var fitnessGoal: UserProfile.FitnessGoal = .maintain
}

final class OnboardingViewModel: ObservableObject {
    @Published var uiState = OnboardingUiState()

    private let userProfileUseCase: UserProfileUseCaseProtocol
    private let appState: AppState

    let totalSteps = 4

    init(userProfileUseCase: UserProfileUseCaseProtocol, appState: AppState) {
        self.userProfileUseCase = userProfileUseCase
        self.appState = appState
    }

    func nextStep() {
        if uiState.currentStep < totalSteps - 1 {
            uiState.currentStep += 1
        }
    }

    func previousStep() {
        if uiState.currentStep > 0 {
            uiState.currentStep -= 1
        }
    }

    func finish() {
        let profile = UserProfile(
            name: uiState.name.isEmpty ? "Usuario" : uiState.name,
            height: uiState.height,
            weight: uiState.weight,
            age: uiState.age,
            gender: uiState.gender,
            activityLevel: uiState.activityLevel,
            fitnessGoal: uiState.fitnessGoal
        )
        userProfileUseCase.saveProfile(profile)
        userProfileUseCase.setOnboardingCompleted(true)
        appState.changeScreen(to: .home)
    }

    func skip() {
        userProfileUseCase.setOnboardingCompleted(true)
        appState.changeScreen(to: .home)
    }
}
