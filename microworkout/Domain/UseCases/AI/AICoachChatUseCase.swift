import Foundation

protocol AICoachChatUseCaseProtocol {
    /// Respuesta del coach trozo a trozo.
    /// - Parameters:
    ///   - context: snapshot de los datos del usuario (lo arma `AIContextUseCase`).
    ///   - question: el turno actual.
    ///   - conversation: turnos anteriores, del más antiguo al más reciente.
    func stream(
        context: AIContext,
        question: String,
        topic: AICoachTopic,
        conversation: [AIChatTurn]
    ) -> AsyncThrowingStream<String, Error>
}

/// Capa fina entre el chat y el repositorio: el ViewModel no debe conocer ni el
/// repositorio ni los DTO de red, y aquí es donde caería la lógica de
/// conversación (resúmenes, recorte de historial) si hiciera falta más adelante.
final class AICoachChatUseCase: AICoachChatUseCaseProtocol {
    private let repository: AICoachRepositoryProtocol

    init(repository: AICoachRepositoryProtocol) {
        self.repository = repository
    }

    func stream(
        context: AIContext,
        question: String,
        topic: AICoachTopic,
        conversation: [AIChatTurn]
    ) -> AsyncThrowingStream<String, Error> {
        repository.streamCoach(
            context: context,
            topic: topic,
            question: question,
            conversation: conversation
        )
    }
}
