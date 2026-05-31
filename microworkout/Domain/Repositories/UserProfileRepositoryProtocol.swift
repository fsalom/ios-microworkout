import Foundation

/// Protocolo para acceder al repositorio del perfil de usuario.
/// `getProfile` y `saveProfile` son async porque, en estado autenticado,
/// hablan con el backend; `hasCompletedOnboarding` se queda síncrono
/// porque es estado del cliente (qué dispositivo mostró ya el onboarding).
protocol UserProfileRepositoryProtocol {
    func saveProfile(_ profile: UserProfile) async throws
    func getProfile() async throws -> UserProfile?
    func setOnboardingCompleted(_ completed: Bool)
    func isOnboardingCompleted() -> Bool
}
