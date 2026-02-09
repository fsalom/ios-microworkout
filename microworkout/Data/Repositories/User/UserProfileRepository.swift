//
//  UserProfileRepository.swift
//  microworkout
//

import Foundation

/// Implementación del repositorio del perfil de usuario.
class UserProfileRepository: UserProfileRepositoryProtocol {
    private let localDataSource: UserLocalDataSource

    init(localDataSource: UserLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func saveProfile(_ profile: UserProfile) {
        localDataSource.save(profile: profile)
    }

    func getProfile() -> UserProfile? {
        localDataSource.getProfile()
    }

    func setOnboardingCompleted(_ completed: Bool) {
        localDataSource.setOnboardingCompleted(completed)
    }

    func isOnboardingCompleted() -> Bool {
        localDataSource.isOnboardingCompleted()
    }
}
