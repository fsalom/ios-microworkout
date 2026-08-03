import Foundation

/// Mismo criterio que el resto de repos (Meals, WorkoutLog, UserProfile):
/// invitado → no hay backend que llamar, así que corta con `notAuthorized`;
/// autenticado → `/v1/ai/coach` y `/v1/ai/insight`.
///
/// No hay variante local: aquí el "offline-first" no aplica porque el modelo no
/// está en el dispositivo. El fallback (consejo calculado en local) es una
/// decisión de producto y vive en `CoachUseCase`, no aquí.
final class AICoachRepository: AICoachRepositoryProtocol {
    private let remote: AICoachRemoteDataSourceProtocol

    init(remote: AICoachRemoteDataSourceProtocol) {
        self.remote = remote
    }

    private func isAuthenticated() async -> Bool {
        await MainActor.run { AuthSession.shared.state.isAuthenticated }
    }

    func streamCoach(
        context: AIContext,
        topic: AICoachTopic,
        question: String?,
        conversation: [AIChatTurn]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                guard await self.isAuthenticated() else {
                    continuation.finish(throwing: DomainError.notAuthorized)
                    return
                }
                let request = AICoachRequestApiDTO(
                    context: context,
                    topic: topic,
                    question: question,
                    conversation: conversation
                )
                do {
                    for try await chunk in self.remote.streamCoach(request) {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: DomainError.map(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func insight(context: AIContext, topic: AICoachTopic) async throws -> CoachInsight {
        guard await isAuthenticated() else { throw DomainError.notAuthorized }
        let request = AICoachRequestApiDTO(
            context: context,
            topic: topic,
            question: nil
        )
        let dto = try await remote.insight(request)
        return dto.toDomain(fallbackTopic: topic)
    }
}
