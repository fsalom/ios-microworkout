import Foundation

/// Una señal del usuario sobre un consejo del coach.
///
/// Es la materia prima con la que el coach puede mejorar: sin saber qué propuestas
/// se aceptan, cuáles se ignoran y qué respuestas molestaron, "aprender" es
/// imposible por construcción. El backend las agrega y se las enseña al modelo en
/// el contexto de las siguientes peticiones.
struct CoachFeedbackSignal: Equatable {
    enum Kind: String {
        /// Una acción de un toque propuesta en una tarjeta.
        case action
        /// La tarjeta entera de una pestaña.
        case insight
        /// Una respuesta del chat.
        case chat
    }

    enum Verdict: String {
        case accepted
        case ignored
        case helpful
        case unhelpful
    }

    let kind: Kind
    let verdict: Verdict
    let topic: AICoachTopic?
    /// Lo que se propuso o contestó, resumido: es lo que hace que "ignoró esto"
    /// signifique algo cuando la tarjeta ya no exista.
    let summary: String
    /// El motivo del usuario, si lo dio (solo tiene sentido en los pulgares abajo).
    let reason: String?

    init(
        kind: Kind, verdict: Verdict, topic: AICoachTopic?,
        summary: String, reason: String? = nil
    ) {
        self.kind = kind
        self.verdict = verdict
        self.topic = topic
        self.summary = summary
        self.reason = reason
    }
}
