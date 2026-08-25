import Foundation

struct WeeklyPlanUiState {
    /// La semana entera, siempre 7 filas de lunes a domingo: la pantalla enseña
    /// también los días sin decidir, que es justo lo que hay que rellenar.
    var days: [WeeklyPlanDayRow] = []
    var planName: String = ""
    /// Catálogo de sesiones para elegir. Vacío = todavía no hay plantillas.
    var sessions: [WorkoutSession] = []
    var isLoading: Bool = true
    var error: String?

    var hasSessions: Bool { !sessions.isEmpty }
    var trainingDayCount: Int { days.filter { $0.sessionId != nil }.count }
}

/// Una fila de la pantalla: un día con lo que tiene asignado, ya resuelto.
struct WeeklyPlanDayRow: Identifiable {
    let weekday: Int
    let weekdayName: String
    var sessionId: UUID?
    var sessionName: String?
    /// Descanso EXPLÍCITO: el día está en el plan, sin sesión. Distinto de "sin
    /// decidir" (el día no está en el plan), que al coach le dice otra cosa.
    var isRest: Bool
    /// La sesión asignada ya no existe: se enseña para que el usuario lo arregle,
    /// no se disimula como descanso.
    var isMissingSession: Bool

    var id: Int { weekday }
}

final class WeeklyPlanViewModel: ObservableObject {
    @Published var uiState: WeeklyPlanUiState = .init()

    private let useCase: WeeklyPlanUseCaseProtocol
    private let workoutLogUseCase: WorkoutLogUseCaseProtocol
    /// El plan tal y como está guardado. Se edita sobre él (no sobre las filas)
    /// para no perder lo que la pantalla no enseña, como las notas por día.
    private var plan: WeeklyPlan = .empty

    init(useCase: WeeklyPlanUseCaseProtocol, workoutLogUseCase: WorkoutLogUseCaseProtocol) {
        self.useCase = useCase
        self.workoutLogUseCase = workoutLogUseCase
    }

    func load() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            // Cada carga con su `try?`: quedarse sin catálogo no puede dejar sin
            // plan, ni al revés.
            let plan = (try? await self.useCase.getPlan()) ?? .empty
            let sessions = (try? await self.workoutLogUseCase.getAllSessions()) ?? []
            self.plan = plan
            self.uiState.planName = plan.name
            self.uiState.sessions = sessions.sorted { $0.name < $1.name }
            self.rebuildRows()
            self.uiState.isLoading = false
        }
    }

    /// Asigna una sesión (o descanso, con `nil`) a un día. Guarda al momento:
    /// el plan es pequeño y un botón de "Guardar" solo añadiría un estado más
    /// que poder perder.
    func assign(sessionId: UUID?, to weekday: Int) {
        var days = plan.days.filter { $0.weekday != weekday }
        let existingNote = plan.day(weekday)?.note
        days.append(PlannedDay(weekday: weekday, sessionId: sessionId, note: existingNote))
        plan.days = days.sorted { $0.weekday < $1.weekday }
        rebuildRows()
        persist()
    }

    /// Quita el día del plan del todo (ni sesión ni descanso: sin decidir).
    func clear(weekday: Int) {
        plan.days.removeAll { $0.weekday == weekday }
        rebuildRows()
        persist()
    }

    func setPlanName(_ name: String) {
        guard name != plan.name else { return }
        plan.name = name
        persist()
    }

    // MARK: - Privado

    private func persist() {
        let snapshot = plan
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.useCase.savePlan(snapshot)
                self.uiState.error = nil
            } catch {
                self.uiState.error = "No se pudo guardar el plan"
            }
        }
    }

    private func rebuildRows() {
        let sessionsById = Dictionary(
            uiState.sessions.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        uiState.days = WeeklyPlan.weekdaysFromMonday.map { weekday in
            let day = plan.day(weekday)
            let session = day?.sessionId.flatMap { sessionsById[$0] }
            return WeeklyPlanDayRow(
                weekday: weekday,
                weekdayName: WeeklyPlan.weekdayName(weekday),
                sessionId: day?.sessionId,
                sessionName: session?.name,
                isRest: day != nil && day?.sessionId == nil,
                isMissingSession: day?.sessionId != nil && session == nil
            )
        }
        uiState.planName = plan.name
    }
}
