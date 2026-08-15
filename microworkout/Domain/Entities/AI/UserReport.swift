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

/// Área de una nota del informe. Espejo de `NoteArea` del backend.
///
/// NO es `AICoachTopic`. Esto era el bug: el campo se lee de una clave llamada
/// `topic` y se parseaba como si fuera el tema del coach, pero el backend escribe
/// áreas (`entreno`, `nutricion`…). De los seis valores solo coincidía `plan`, así
/// que cinco de cada seis notas se quedaban sin etiqueta en el perfil.
public enum UserReportArea: String, Equatable, CaseIterable {
    case entreno
    case nutricion
    case biometria
    case descanso
    case plan
    case vida

    /// Etiqueta para la píldora de la nota.
    public var label: String {
        switch self {
        case .entreno: return "ENTRENO"
        case .nutricion: return "NUTRICIÓN"
        case .biometria: return "BIOMETRÍA"
        case .descanso: return "DESCANSO"
        case .plan: return "PLAN"
        case .vida: return "VIDA"
        }
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
    /// Área de lo aprendido, si el coach la etiquetó.
    public let area: UserReportArea?
    public let createdAt: Date

    public init(
        id: Int,
        content: String,
        source: Source,
        area: UserReportArea? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.content = content
        self.source = source
        self.area = area
        self.createdAt = createdAt
    }
}
