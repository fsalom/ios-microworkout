//
//  UserProfileUseCase.swift
//  microworkout
//

import Foundation

/// Implementación de los casos de uso para gestionar el perfil de usuario.
class UserProfileUseCase: UserProfileUseCaseProtocol {
    private let repository: UserProfileRepositoryProtocol

    init(repository: UserProfileRepositoryProtocol) {
        self.repository = repository
    }

    func saveProfile(_ profile: UserProfile) {
        repository.saveProfile(profile)
    }

    func getProfile() -> UserProfile? {
        repository.getProfile()
    }

    func setOnboardingCompleted(_ completed: Bool) {
        repository.setOnboardingCompleted(completed)
    }

    func hasCompletedOnboarding() -> Bool {
        repository.isOnboardingCompleted()
    }
}
