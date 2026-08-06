import Foundation

/// Contexto del usuario que no está en los números.
///
/// Los datos (series, comidas, peso) ya los tiene la app. Esto es el resto: una
/// lesión que arrastra, a qué hora entrena, que se va de viaje en septiembre. El
/// coach lo recibe en cada conversación.
public struct UserReport: Equatable {
    /// Lo que escribe el usuario.
    public var content: String
    /// Notas que ha ido anotando el coach. El usuario puede borrarlas.
    public var notes: [UserReportNote]
    public var updatedAt: Date?

    public init(content: String = "", notes: [UserReportNote] = [], updatedAt: Date? = nil) {
        self.content = content
        self.notes = notes
        self.updatedAt = updatedAt
    }

    /// Notas escritas por el coach, que son las que se muestran aparte del texto
    /// del usuario para que quede claro quién dijo qué.
    public var coachNotes: [UserReportNote] {
        notes.filter { $0.source == .coach }
    }

    public var isEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && notes.isEmpty
    }
}

public struct UserReportNote: Identifiable, Equatable {
    public enum Source: String {
        case user
        case coach
    }

    public let id: Int
    public let content: String
    public let source: Source
    /// Área del coach que la generó, si vino de una conversación con tema.
    public let topic: AICoachTopic?
    public let createdAt: Date

    public init(
        id: Int,
        content: String,
        source: Source,
        topic: AICoachTopic? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.content = content
        self.source = source
        self.topic = topic
        self.createdAt = createdAt
    }
}
