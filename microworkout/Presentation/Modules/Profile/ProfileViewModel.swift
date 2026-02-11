import SwiftUI
import Combine

struct ProfileUiState {
    var name: String = ""
    var weight: Double = 70
    var height: Double = 170
    var age: Int = 30
    var gender: UserProfile.Gender = .male
    var activityLevel: UserProfile.ActivityLevel = .moderate
    var hasProfile: Bool = false
    var dailyCalorieTarget: Double = 0
    var isEditing: Bool = false
}

class ProfileViewModel: ObservableObject {
    @Published var uiState: ProfileUiState = .init()

    private var userProfileUseCase: UserProfileUseCaseProtocol

    init(userProfileUseCase: UserProfileUseCaseProtocol) {
        self.userProfileUseCase = userProfileUseCase
        loadProfile()
    }

    func loadProfile() {
        guard let profile = userProfileUseCase.getProfile() else { return }
        uiState.name = profile.name
        uiState.weight = profile.weight
        uiState.height = profile.height
        uiState.age = profile.age
        uiState.gender = profile.gender
        uiState.activityLevel = profile.activityLevel
        uiState.hasProfile = true
        uiState.dailyCalorieTarget = profile.dailyCalorieTarget
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
            activityLevel: uiState.activityLevel
        )
        userProfileUseCase.saveProfile(profile)
        userProfileUseCase.setOnboardingCompleted(true)
        uiState.hasProfile = true
        uiState.dailyCalorieTarget = profile.dailyCalorieTarget
        uiState.isEditing = false
    }
}
