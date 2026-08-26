import Foundation

/// Captura las señales del usuario sobre el coach y las manda a la cuenta.
///
/// Todo aquí es deliberadamente no bloqueante y sin errores hacia fuera: el
/// feedback es un subproducto de usar la app, y perder una señal por estar sin
/// red es aceptable — molestar al usuario por ella, no.
protocol CoachFeedbackUseCaseProtocol {
    /// El usuario tocó una acción propuesta. Se marca como aplicada (para que la
    /// renovación de la tarjeta no la cuente como ignorada) y se reporta.
    func actionApplied(_ action: CoachAction, topic: AICoachTopic) async
    /// La tarjeta se renovó con estas acciones sin tocar: las no aplicadas se
    /// reportan como ignoradas.
    func actionsSuperseded(_ actions: [CoachAction], topic: AICoachTopic) async
    /// Pulgar arriba/abajo en una tarjeta.
    func insightRated(_ insight: CoachInsight, helpful: Bool, reason: String?) async
    /// Pulgar arriba/abajo en una respuesta del chat.
    func chatRated(topic: AICoachTopic, answer: String, helpful: Bool, reason: String?) async
}

final class CoachFeedbackUseCase: CoachFeedbackUseCaseProtocol {
    /// Cuántos ids de acciones aplicadas se recuerdan. El id de una acción es
    /// estable ("add_food:Pollo:150"), así que recordarlo también evita reportar
    /// como ignorada una propuesta idéntica que el usuario ya aceptó otro día.
    static let appliedIdsCap = 200
    private static let appliedKey = "coachFeedback.appliedActionIds"

    private let repository: CoachFeedbackRepositoryProtocol
    private let storage: UserDefaultsManagerProtocol

    init(repository: CoachFeedbackRepositoryProtocol, storage: UserDefaultsManagerProtocol) {
        self.repository = repository
        self.storage = storage
    }

    func actionApplied(_ action: CoachAction, topic: AICoachTopic) async {
        markApplied(action.id)
        await send(CoachFeedbackSignal(
            kind: .action, verdict: .accepted, topic: topic, summary: action.label
        ))
    }

    func actionsSuperseded(_ actions: [CoachAction], topic: AICoachTopic) async {
        let applied = Set(appliedIds())
        for action in actions where !applied.contains(action.id) {
            await send(CoachFeedbackSignal(
                kind: .action, verdict: .ignored, topic: topic, summary: action.label
            ))
        }
    }

    func insightRated(_ insight: CoachInsight, helpful: Bool, reason: String?) async {
        await send(CoachFeedbackSignal(
            kind: .insight,
            verdict: helpful ? .helpful : .unhelpful,
            topic: insight.topic,
            summary: insight.title,
            reason: reason
        ))
    }

    func chatRated(topic: AICoachTopic, answer: String, helpful: Bool, reason: String?) async {
        // El arranque de la respuesta identifica de qué hablaba sin guardar la
        // parrafada entera: el backend corta en 200 igualmente.
        let excerpt = answer
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        guard !excerpt.isEmpty else { return }
        await send(CoachFeedbackSignal(
            kind: .chat,
            verdict: helpful ? .helpful : .unhelpful,
            topic: topic,
            summary: String(excerpt.prefix(200)),
            reason: reason
        ))
    }

    // MARK: - Privado

    private func send(_ signal: CoachFeedbackSignal) async {
        // `try?`: una señal perdida no vale una alerta. La siguiente llegará.
        try? await repository.send(signal)
    }

    private func appliedIds() -> [String] {
        storage.get(forKey: Self.appliedKey) ?? []
    }

    private func markApplied(_ id: String) {
        var ids = appliedIds()
        ids.removeAll { $0 == id }
        ids.append(id)
        // FIFO con tope: lo viejo caduca solo. Sin esto la lista crece para siempre.
        if ids.count > Self.appliedIdsCap {
            ids.removeFirst(ids.count - Self.appliedIdsCap)
        }
        storage.save(ids, forKey: Self.appliedKey)
    }
}
