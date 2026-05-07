import Foundation

/// Insight producido por el coach IA para mostrarse embebido en una pantalla.
public struct CoachInsight: Identifiable, Equatable {
    public enum Kind: String {
        case workout
        case nutrition
        case home
    }

    public let id: UUID
    public let kind: Kind
    public let title: String
    public let body: String
    public let bullets: [String]
    /// Prompt prefijado para abrir el chat continuando esta conversación.
    public let prompt: String

    public init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        body: String,
        bullets: [String] = [],
        prompt: String
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.bullets = bullets
        self.prompt = prompt
    }
}
