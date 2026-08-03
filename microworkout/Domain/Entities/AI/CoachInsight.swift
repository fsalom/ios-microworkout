import Foundation

/// Insight producido por el coach IA para mostrarse embebido en una pantalla.
public struct CoachInsight: Identifiable, Equatable {
    public let id: UUID
    /// Área del consejo. Es el mismo enum que viaja al backend, para no tener
    /// dos taxonomías que mantener en sincronía.
    public let topic: AICoachTopic
    public let title: String
    public let body: String
    public let bullets: [String]
    /// Prompt prefijado para abrir el chat continuando esta conversación.
    public let prompt: String
    /// `false` cuando el consejo lo ha calculado la app en local (invitado o sin
    /// red) en vez del modelo. La tarjeta lo indica para no atribuirle a la IA
    /// algo que no ha dicho.
    public let isFromModel: Bool

    public init(
        id: UUID = UUID(),
        topic: AICoachTopic,
        title: String,
        body: String,
        bullets: [String] = [],
        prompt: String,
        isFromModel: Bool = false
    ) {
        self.id = id
        self.topic = topic
        self.title = title
        self.body = body
        self.bullets = bullets
        self.prompt = prompt
        self.isFromModel = isFromModel
    }
}
