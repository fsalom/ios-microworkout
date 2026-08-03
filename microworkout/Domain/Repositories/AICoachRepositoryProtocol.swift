import Foundation

/// Acceso al coach IA. Requiere cuenta: el modelo vive en el backend, así que en
/// modo invitado estos métodos fallan con `DomainError.notAuthorized` y es el use
/// case quien decide el plan B (consejo heurístico local).
protocol AICoachRepositoryProtocol {
    /// Respuesta del chat, trozo a trozo.
    /// - Parameters:
    ///   - conversation: turnos previos; el turno actual va en `question`.
    func streamCoach(
        context: AIContext,
        topic: AICoachTopic,
        question: String?,
        conversation: [AIChatTurn]
    ) -> AsyncThrowingStream<String, Error>

    /// Consejo compacto para la tarjeta de una pestaña.
    func insight(context: AIContext, topic: AICoachTopic) async throws -> CoachInsight
}
