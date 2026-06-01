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

    func getProfile() async throws -> UserProfile? {
        if await isAuthenticated() {
            return try await remote.get()?.toDomain()
        }
        return local.getProfile()
    }

    func setOnboardingCompleted(_ completed: Bool) {
        local.setOnboardingCompleted(completed)
    }

    func isOnboardingCompleted() -> Bool {
        local.isOnboardingCompleted()
    }
}
