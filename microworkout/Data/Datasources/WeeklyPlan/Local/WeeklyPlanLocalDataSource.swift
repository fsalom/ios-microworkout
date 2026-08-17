import Foundation

protocol WeeklyPlanLocalDataSourceProtocol {
    func getPlan() -> WeeklyPlanDTO?
    func savePlan(_ plan: WeeklyPlanDTO)
}

/// El plan en el dispositivo.
///
/// Existe copia local aunque el plan sea sobre todo para el coach (que corre en el
/// servidor): la pantalla lo pinta en cada arranque y un invitado sin cuenta tiene
/// que poder planificar su semana igual que puede crear sesiones.
final class WeeklyPlanLocalDataSource: WeeklyPlanLocalDataSourceProtocol {
    private enum Keys: String {
        case plan = "weeklyPlan.current"
    }

    private let storage: UserDefaultsManagerProtocol

    init(storage: UserDefaultsManagerProtocol) {
        self.storage = storage
    }

    func getPlan() -> WeeklyPlanDTO? {
        storage.get(forKey: Keys.plan.rawValue)
    }

    func savePlan(_ plan: WeeklyPlanDTO) {
        storage.save(plan, forKey: Keys.plan.rawValue)
    }
}

// MARK: - DTO

struct WeeklyPlanDTO: Codable {
    var name: String
    var days: [PlannedDayDTO]

    struct PlannedDayDTO: Codable {
        var weekday: Int
        var sessionId: UUID?
        var note: String?
    }
}

extension WeeklyPlan {
    func toDTO() -> WeeklyPlanDTO {
        WeeklyPlanDTO(
            name: name,
            days: days.map {
                WeeklyPlanDTO.PlannedDayDTO(weekday: $0.weekday, sessionId: $0.sessionId, note: $0.note)
            }
        )
    }
}

extension WeeklyPlanDTO {
    func toDomain() -> WeeklyPlan {
        WeeklyPlan(
            name: name,
            // Un weekday fuera de 1...7 no es un día: se descarta en vez de dejar
            // que llegue al dominio y reviente al pedir su nombre.
            days: days
                .filter { (1...7).contains($0.weekday) }
                .map { PlannedDay(weekday: $0.weekday, sessionId: $0.sessionId, note: $0.note) }
                .sorted { $0.weekday < $1.weekday }
        )
    }
}
