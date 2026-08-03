import Foundation

/// Un turno de conversación con el coach, tal y como viaja al backend.
///
/// La capa de presentación tiene su propio modelo (`AIChatMessage`, con id y
/// timestamp para SwiftUI); esto es solo el par rol/contenido que el modelo
/// necesita para tener memoria de la conversación.
public struct AIChatTurn: Equatable, Sendable {
    public enum Role: String, Sendable {
        case user
        case assistant
    }

    public let role: Role
    public let content: String

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}
