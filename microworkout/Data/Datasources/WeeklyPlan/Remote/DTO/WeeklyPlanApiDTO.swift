import Foundation

/// Forma que se intercambia con `/v1/weekly-plan`.
///
/// El backend valida con `extra="forbid"`: cualquier clave que no esté en su modelo
/// devuelve 422, así que esta estructura y `UpsertWeeklyPlanDTO` del servidor se
/// cambian juntas.
struct WeeklyPlanApiDTO: Codable {
    let name: String
    let days: [PlannedDayApiDTO]

    struct PlannedDayApiDTO: Codable {
        let weekday: Int
        let sessionId: UUID?
        let note: String?

        enum CodingKeys: String, CodingKey {
            case weekday
            case sessionId = "session_id"
            case note
        }
    }
}

extension WeeklyPlanApiDTO {
    func toDomain() -> WeeklyPlan {
        WeeklyPlan(
            name: name,
            days: days
                .filter { (1...7).contains($0.weekday) }
                .map { PlannedDay(weekday: $0.weekday, sessionId: $0.sessionId, note: $0.note) }
                .sorted { $0.weekday < $1.weekday }
        )
    }

    /// El cuerpo del PUT, ya en las claves del servidor.
    ///
    /// Se construye a mano en vez de codificar el DTO porque `Endpoint` recibe
    /// `[String: Any]`, igual que en el resto de datasources remotos. Las claves
    /// ausentes son deliberadas: el backend las trata como `None`, y mandar
    /// `null` explícito en `note` no aporta nada.
    static func payload(for plan: WeeklyPlan) -> [String: Any] {
        [
            "name": plan.name,
            "days": plan.days.map { day -> [String: Any] in
                var body: [String: Any] = ["weekday": day.weekday]
                if let sessionId = day.sessionId { body["session_id"] = sessionId.uuidString }
                if let note = day.note, !note.isEmpty { body["note"] = note }
                return body
            }
        ]
    }
}
