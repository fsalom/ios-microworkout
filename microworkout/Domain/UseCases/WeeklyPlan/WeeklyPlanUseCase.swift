import Foundation

/// Un día del plan ya resuelto: con el nombre de la sesión, no solo su id.
///
/// Existe porque el id no se le puede mostrar a nadie ni mandárselo al coach. La
/// resolución vive en el dominio y no en la vista para que el texto que lee la IA y
/// el que ve el usuario salgan del mismo sitio.
struct ResolvedPlannedDay: Identifiable, Equatable {
    let weekday: Int
    let session: WorkoutSession?
    let note: String?
    /// `true` si el día apunta a una sesión que ya no existe (se borró después de
    /// planificarla). No se silencia: es lo que hay que enseñarle al usuario para
    /// que lo arregle.
    let isMissingSession: Bool

    var id: Int { weekday }

    var isRest: Bool { session == nil && !isMissingSession }

    var weekdayName: String { WeeklyPlan.weekdayName(weekday) }
}

protocol WeeklyPlanUseCaseProtocol {
    func getPlan() async throws -> WeeklyPlan
    func savePlan(_ plan: WeeklyPlan) async throws
    /// El plan con los nombres de sesión ya resueltos, ordenado de lunes a domingo.
    func getResolvedWeek() async throws -> [ResolvedPlannedDay]
    /// Lo planificado para una fecha (por defecto hoy), ya resuelto.
    func plannedDay(on date: Date) async throws -> ResolvedPlannedDay?
}

extension WeeklyPlanUseCaseProtocol {
    func plannedToday() async throws -> ResolvedPlannedDay? {
        try await plannedDay(on: Date())
    }
}

final class WeeklyPlanUseCase: WeeklyPlanUseCaseProtocol {
    private let repository: WeeklyPlanRepositoryProtocol
    private let workoutLogUseCase: WorkoutLogUseCaseProtocol

    init(repository: WeeklyPlanRepositoryProtocol, workoutLogUseCase: WorkoutLogUseCaseProtocol) {
        self.repository = repository
        self.workoutLogUseCase = workoutLogUseCase
    }

    func getPlan() async throws -> WeeklyPlan {
        try await repository.getPlan()
    }

    func savePlan(_ plan: WeeklyPlan) async throws {
        try await repository.savePlan(plan)
    }

    func getResolvedWeek() async throws -> [ResolvedPlannedDay] {
        let plan = try await repository.getPlan()
        guard !plan.days.isEmpty else { return [] }
        let sessions = try await sessionsById()
        return plan.orderedFromMonday.map { Self.resolve($0, in: sessions) }
    }

    func plannedDay(on date: Date) async throws -> ResolvedPlannedDay? {
        let plan = try await repository.getPlan()
        guard let day = plan.day(on: date) else { return nil }
        return Self.resolve(day, in: try await sessionsById())
    }

    private func sessionsById() async throws -> [UUID: WorkoutSession] {
        // `try?`: sin sesiones el plan sigue siendo legible (dice qué días entrenas
        // y qué días descansas), y quedarse sin plan por no poder leer el catálogo
        // sería peor que enseñarlo con los nombres a medias.
        let sessions = (try? await workoutLogUseCase.getAllSessions()) ?? []
        return Dictionary(sessions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private static func resolve(
        _ day: PlannedDay,
        in sessions: [UUID: WorkoutSession]
    ) -> ResolvedPlannedDay {
        guard let sessionId = day.sessionId else {
            return ResolvedPlannedDay(
                weekday: day.weekday, session: nil, note: day.note, isMissingSession: false
            )
        }
        let session = sessions[sessionId]
        return ResolvedPlannedDay(
            weekday: day.weekday,
            session: session,
            note: day.note,
            isMissingSession: session == nil
        )
    }
}
