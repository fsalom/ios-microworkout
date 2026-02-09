//
//  UserProfileRepositoryProtocol.swift
//  microworkout
//

import Foundation

/// Protocolo para acceder al repositorio del perfil de usuario.
protocol UserProfileRepositoryProtocol {
    func saveProfile(_ profile: UserProfile)
    func getProfile() -> UserProfile?
    func setOnboardingCompleted(_ completed: Bool)
    func isOnboardingCompleted() -> Bool
}
