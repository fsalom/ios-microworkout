import Foundation

/// Respuesta de `GET/PUT /v1/profile/report`.
struct UserReportApiDTO: Decodable {
    let content: String
    let notes: [ReportNoteApiDTO]
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case content, notes
        case updatedAt = "updated_at"
    }

    func toDomain() -> UserReport {
        UserReport(
            content: content,
            notes: notes.map { $0.toDomain() },
            updatedAt: updatedAt
        )
    }
}

struct ReportNoteApiDTO: Decodable {
    let id: Int
    let content: String
    let source: String
    let topic: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, content, source, topic
        case createdAt = "created_at"
    }

    func toDomain() -> UserReportNote {
        UserReportNote(
            id: id,
            content: content,
            // Una fuente desconocida se trata como del coach: es la que el usuario
            // puede borrar, así que es el lado seguro si el backend añade otra.
            source: UserReportNote.Source(rawValue: source) ?? .coach,
            topic: topic.flatMap { AICoachTopic(rawValue: $0) },
            createdAt: createdAt
        )
    }
}
