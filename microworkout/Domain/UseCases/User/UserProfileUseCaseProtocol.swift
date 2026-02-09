//
//  UserProfileUseCaseProtocol.swift
//  microworkout
//

import Foundation

/// Casos de uso para gestionar el perfil de usuario.
protocol UserProfileUseCaseProtocol {
    /// Guarda el perfil de usuario.
    func saveProfile(_ profile: UserProfile)

    /// Recupera el perfil de usuario.
    func getProfile() -> UserProfile?

    /// Marca el onboarding como completado.
    func setOnboardingCompleted(_ completed: Bool)

    /// Comprueba si el onboarding ha sido completado.
    func hasCompletedOnboarding() -> Bool
}
