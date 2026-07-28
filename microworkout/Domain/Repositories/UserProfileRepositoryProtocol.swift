import Foundation

/// Protocolo para acceder al repositorio del perfil de usuario.
/// `getProfile` y `saveProfile` son async porque, en estado autenticado,
/// hablan con el backend; `hasCompletedOnboarding` se queda síncrono
/// porque es estado del cliente (qué dispositivo mostró ya el onboarding).
protocol UserProfileRepositoryProtocol {
    func saveProfile(_ profile: UserProfile) async throws
    func getProfile() async throws -> UserProfile?
    /// 1 si hay perfil local que aún no está en la cuenta; 0 en otro caso.
    func pendingSyncCount() async throws -> Int
    /// Sube el perfil local a la cuenta si el servidor no tiene uno (modelo
    /// espejo: no borra la copia local, y no pisa un perfil ya existente en el
    /// servidor). Devuelve 1 si subió, 0 si no.
    func syncLocalToRemote() async throws -> Int
    func setOnboardingCompleted(_ completed: Bool)
    func isOnboardingCompleted() -> Bool
}
