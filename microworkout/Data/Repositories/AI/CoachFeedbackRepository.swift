import Foundation

/// Sin variante local: una señal sin cuenta no tiene a quién servir, porque el
/// coach corre en el servidor. En modo invitado se descarta en silencio.
final class CoachFeedbackRepository: CoachFeedbackRepositoryProtocol {
    private let remote: CoachFeedbackRemoteDataSourceProtocol
    private let session: AuthStateProviding

    init(
        remote: CoachFeedbackRemoteDataSourceProtocol,
        session: AuthStateProviding = SharedAuthState()
    ) {
        self.remote = remote
        self.session = session
    }

    func send(_ signal: CoachFeedbackSignal) async throws {
        guard await session.isAuthenticated else { return }
        try await remote.send(signal)
    }
}
