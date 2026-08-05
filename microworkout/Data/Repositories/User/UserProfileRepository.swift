import Foundation

/// Dispatch igual al de `TrainingRepository`/`ExerciseRepository`:
/// invitado → `UserDefaults`; autenticado → `/v1/profile`.
/// El flag de "onboarding completado" siempre se guarda local — es estado del
/// cliente (qué dispositivo enseñó el onboarding), no del servidor.
final class UserProfileRepository: UserProfileRepositoryProtocol {
    private let local: UserLocalDataSource
    private let remote: UserProfileRemoteDataSourceProtocol

    init(local: UserLocalDataSource, remote: UserProfileRemoteDataSourceProtocol) {
        self.local = local
        self.remote = remote
    }

    private func isAuthenticated() async -> Bool {
        await MainActor.run { AuthSession.shared.state.isAuthenticated }
    }

    func saveProfile(_ profile: UserProfile) async throws {
        if await isAuthenticated() {
            _ = try await remote.upsert(profile)
            return
        }
        local.save(profile: profile)
    }

    /// Con sesión, el perfil de la cuenta manda; pero si la cuenta **no tiene**
    /// perfil todavía (creado como invitado y sin subir), se usa el local en vez de
    /// devolver `nil`. Devolver `nil` dejaba la app sin objetivo de calorías: el
    /// anillo y "OBJETIVO" salían en "—" y el cálculo semanal no podía hacerse,
    /// aunque el perfil estuviera relleno en el dispositivo.
    func getProfile() async throws -> UserProfile? {
        guard await isAuthenticated() else { return local.getProfile() }

        if let remoteProfile = try await remote.get()?.toDomain() {
            return remoteProfile
        }
        return local.getProfile()
    }

    /// Modelo espejo: 1 si hay perfil local y la cuenta aún no tiene uno; 0 si no.
    func pendingSyncCount() async throws -> Int {
        guard local.getProfile() != nil else { return 0 }
        return try await remote.get() == nil ? 1 : 0
    }

    /// Sube el perfil local si la cuenta no tiene uno. No pisa un perfil ya
    /// existente en el servidor y nunca borra la copia local.
    func syncLocalToRemote() async throws -> Int {
        guard let localProfile = local.getProfile() else { return 0 }
        if try await remote.get() != nil { return 0 }
        _ = try await remote.upsert(localProfile)
        return 1
    }

    func setOnboardingCompleted(_ completed: Bool) {
        local.setOnboardingCompleted(completed)
    }

    func isOnboardingCompleted() -> Bool {
        local.isOnboardingCompleted()
    }
}
