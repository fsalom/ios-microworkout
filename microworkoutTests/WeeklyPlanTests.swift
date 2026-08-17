import XCTest
@testable import microworkout

/// El plan semanal: qué toca cada día.
///
/// Los dos sitios donde esto se rompe en silencio son la numeración de días
/// (`Calendar` usa 1=domingo, `date.weekday()` de Python usa 0=lunes) y la
/// sincronización, que compara un plan local con uno que el servidor ha
/// normalizado. Un error en el primero mueve el entreno de día; en el segundo, el
/// plan aparece como pendiente para siempre o —peor— se pisa al iniciar sesión.
final class WeeklyPlanTests: XCTestCase {

    // MARK: - Dobles

    private enum Fake: Error { case offline }

    private final class FakeLocal: WeeklyPlanLocalDataSourceProtocol {
        var plan: WeeklyPlanDTO?
        private(set) var saveCount = 0

        func getPlan() -> WeeklyPlanDTO? { plan }
        func savePlan(_ plan: WeeklyPlanDTO) {
            self.plan = plan
            saveCount += 1
        }
    }

    private final class FakeRemote: WeeklyPlanRemoteDataSourceProtocol {
        var plan = WeeklyPlanApiDTO(name: "", days: [])
        var isOffline = false
        private(set) var upserted: [WeeklyPlan] = []

        func get() async throws -> WeeklyPlanApiDTO {
            if isOffline { throw Fake.offline }
            return plan
        }

        func upsert(_ plan: WeeklyPlan) async throws -> WeeklyPlanApiDTO {
            if isOffline { throw Fake.offline }
            upserted.append(plan)
            // El servidor normaliza al guardar, igual que el de verdad: recorta el
            // nombre y devuelve las notas vacías como ausentes.
            self.plan = WeeklyPlanApiDTO(
                name: plan.name.trimmingCharacters(in: .whitespaces),
                days: plan.days.map {
                    let note = $0.note?.trimmingCharacters(in: .whitespaces)
                    return WeeklyPlanApiDTO.PlannedDayApiDTO(
                        weekday: $0.weekday,
                        sessionId: $0.sessionId,
                        note: (note?.isEmpty ?? true) ? nil : note
                    )
                }
            )
            return self.plan
        }
    }

    private struct StubSession: AuthStateProviding {
        let authenticated: Bool
        var isAuthenticated: Bool { get async { authenticated } }
    }

    private final class FakeWorkoutLogUseCase: WorkoutLogUseCaseProtocol {
        var sessions: [WorkoutSession] = []
        var failsOnSessions = false

        func getAllSessions() async throws -> [WorkoutSession] {
            if failsOnSessions { throw Fake.offline }
            return sessions
        }
        func saveSession(_ session: WorkoutSession) async throws {}
        func deleteSession(id: String) async throws {}
        func getAllLogs() async throws -> [WorkoutLog] { [] }
        func saveLog(_ log: WorkoutLog) async throws {}
        func deleteLog(id: String) async throws {}
        func getPreviousLoggedExercise(
            sessionId: UUID?, exerciseId: UUID, beforeLogId: UUID?
        ) async throws -> (exercise: LoggedExercise, date: Date)? { nil }
    }

    // MARK: - Numeración de días

    /// Un plan de lunes tiene que caer en lunes. Con `date.weekday()` europeo
    /// (0=lunes) en vez del índice de `Calendar` (1=domingo), esto se desplaza un
    /// día y el usuario ve el entreno del lunes anunciado el domingo.
    func testDayOnDateUsesCalendarWeekday() throws {
        let push = UUID()
        let plan = WeeklyPlan(name: "Fuerza", days: [
            PlannedDay(weekday: 2, sessionId: push),   // lunes
            PlannedDay(weekday: 1, sessionId: nil)     // domingo, descanso
        ])

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        var components = DateComponents()
        components.year = 2026; components.month = 8; components.day = 17  // lunes
        let monday = calendar.date(from: components)!
        let sunday = calendar.date(byAdding: .day, value: -1, to: monday)!

        XCTAssertEqual(plan.day(on: monday, calendar: calendar)?.sessionId, push)
        XCTAssertEqual(plan.day(on: sunday, calendar: calendar)?.weekday, 1)
        XCTAssertTrue(plan.day(on: sunday, calendar: calendar)!.isRest)
    }

    /// Se lee de lunes a domingo, no de 1 a 7: nadie planifica una semana que
    /// empieza en domingo.
    func testOrderedFromMondayPutsSundayLast() {
        let plan = WeeklyPlan(days: (1...7).map { PlannedDay(weekday: $0) })
        XCTAssertEqual(plan.orderedFromMonday.map(\.weekday), [2, 3, 4, 5, 6, 7, 1])
    }

    func testIsEmptyIgnoresRestOnlyPlan() {
        // Solo días de descanso y sin nombre: no hay nada que subir ni que contar.
        XCTAssertTrue(WeeklyPlan(days: [PlannedDay(weekday: 2), PlannedDay(weekday: 3)]).isEmpty)
        XCTAssertFalse(WeeklyPlan(days: [PlannedDay(weekday: 2, sessionId: UUID())]).isEmpty)
        XCTAssertFalse(WeeklyPlan(name: "Fuerza").isEmpty)
    }

    // MARK: - Lectura

    /// El caso que ya rompió con los entrenos y con las comidas: iniciar sesión no
    /// puede hacer desaparecer lo que hay en el dispositivo. La cuenta todavía no
    /// tiene plan (devuelve uno vacío) y el local tiene que ganar.
    func testEmptyRemotePlanDoesNotHideLocalPlan() async throws {
        let local = FakeLocal()
        let remote = FakeRemote()
        let push = UUID()
        local.plan = WeeklyPlan(name: "Fuerza", days: [
            PlannedDay(weekday: 2, sessionId: push)
        ]).toDTO()

        let repository = WeeklyPlanRepository(
            local: local, remote: remote, session: StubSession(authenticated: true)
        )

        let plan = try await repository.getPlan()
        XCTAssertEqual(plan.name, "Fuerza")
        XCTAssertEqual(plan.day(2)?.sessionId, push)
    }

    /// Sin red se sigue con la copia del dispositivo. Propagar el error dejaría la
    /// pantalla en blanco por estar en el metro.
    func testOfflineReadFallsBackToLocal() async throws {
        let local = FakeLocal()
        let remote = FakeRemote()
        remote.isOffline = true
        local.plan = WeeklyPlan(name: "Local", days: [PlannedDay(weekday: 4, sessionId: UUID())]).toDTO()

        let repository = WeeklyPlanRepository(
            local: local, remote: remote, session: StubSession(authenticated: true)
        )

        let actual1 = try await repository.getPlan().name
        XCTAssertEqual(actual1, "Local")
    }

    /// El plan hecho en otro móvil se refleja en este, para que esté disponible sin
    /// conexión.
    func testRemotePlanIsMirroredLocally() async throws {
        let local = FakeLocal()
        let remote = FakeRemote()
        let pull = UUID()
        remote.plan = WeeklyPlanApiDTO(name: "Del otro móvil", days: [
            .init(weekday: 5, sessionId: pull, note: nil)
        ])

        let repository = WeeklyPlanRepository(
            local: local, remote: remote, session: StubSession(authenticated: true)
        )

        let actual2 = try await repository.getPlan().name
        XCTAssertEqual(actual2, "Del otro móvil")
        XCTAssertEqual(local.plan?.toDomain().day(5)?.sessionId, pull)
    }

    // MARK: - Escritura

    /// Guardar tiene que dejar el plan en el dispositivo aunque el servidor falle:
    /// todos los llamantes usan `try?`, así que un throw aquí se traga el plan.
    func testSaveKeepsPlanWhenServerFails() async throws {
        let local = FakeLocal()
        let remote = FakeRemote()
        remote.isOffline = true

        let repository = WeeklyPlanRepository(
            local: local, remote: remote, session: StubSession(authenticated: true)
        )

        try await repository.savePlan(WeeklyPlan(name: "Fuerza", days: [
            PlannedDay(weekday: 2, sessionId: UUID())
        ]))

        XCTAssertEqual(local.plan?.name, "Fuerza")
        XCTAssertTrue(remote.upserted.isEmpty)
        // Y queda pendiente de subir, para que la próxima sincronización lo recoja.
        remote.isOffline = false
        let actual3 = try await repository.pendingSyncCount()
        XCTAssertEqual(actual3, 1)
    }

    func testGuestSavesOnlyLocally() async throws {
        let local = FakeLocal()
        let remote = FakeRemote()

        let repository = WeeklyPlanRepository(
            local: local, remote: remote, session: StubSession(authenticated: false)
        )

        try await repository.savePlan(WeeklyPlan(name: "Invitado", days: [PlannedDay(weekday: 3)]))
        XCTAssertEqual(local.plan?.name, "Invitado")
        XCTAssertTrue(remote.upserted.isEmpty)
    }

    // MARK: - Sincronización

    /// Lo que el servidor normaliza no cuenta como diferencia. Comparando los
    /// structs tal cual, un plan ya subido saldría como pendiente en cada
    /// sincronización y se reenviaría eternamente.
    func testNormalizedDifferencesAreNotPending() async throws {
        let local = FakeLocal()
        let remote = FakeRemote()
        let push = UUID()

        let repository = WeeklyPlanRepository(
            local: local, remote: remote, session: StubSession(authenticated: true)
        )

        // Nombre con espacios y nota vacía: el servidor devolverá ambos limpios.
        try await repository.savePlan(WeeklyPlan(name: "  Fuerza  ", days: [
            PlannedDay(weekday: 2, sessionId: push, note: "   ")
        ]))

        XCTAssertEqual(remote.upserted.count, 1)
        let actual4 = try await repository.pendingSyncCount()
        XCTAssertEqual(actual4, 0)
        let actual5 = try await repository.syncLocalToRemote()
        XCTAssertEqual(actual5, 0)
        XCTAssertEqual(remote.upserted.count, 1, "no debe reenviarse un plan ya subido")
    }

    func testChangedPlanIsUploadedOnce() async throws {
        let local = FakeLocal()
        let remote = FakeRemote()
        local.plan = WeeklyPlan(name: "Fuerza", days: [
            PlannedDay(weekday: 2, sessionId: UUID())
        ]).toDTO()

        let repository = WeeklyPlanRepository(
            local: local, remote: remote, session: StubSession(authenticated: true)
        )

        let actual6 = try await repository.pendingSyncCount()
        XCTAssertEqual(actual6, 1)
        let actual7 = try await repository.syncLocalToRemote()
        XCTAssertEqual(actual7, 1)
        let actual8 = try await repository.pendingSyncCount()
        XCTAssertEqual(actual8, 0)
    }

    /// Un plan vacío no es un plan pendiente: no se molesta al servidor por él.
    func testEmptyPlanIsNeverPending() async throws {
        let local = FakeLocal()
        let remote = FakeRemote()
        remote.isOffline = true   // si lo consultara, fallaría

        let repository = WeeklyPlanRepository(
            local: local, remote: remote, session: StubSession(authenticated: true)
        )

        let actual9 = try await repository.pendingSyncCount()
        XCTAssertEqual(actual9, 0)
        let actual10 = try await repository.syncLocalToRemote()
        XCTAssertEqual(actual10, 0)
    }

    // MARK: - Resolución de nombres

    func testResolvedWeekNamesSessionsAndFlagsMissingOnes() async throws {
        let local = FakeLocal()
        let remote = FakeRemote()
        let push = UUID()
        let deleted = UUID()
        local.plan = WeeklyPlan(name: "Fuerza", days: [
            PlannedDay(weekday: 2, sessionId: push),
            PlannedDay(weekday: 3, sessionId: nil, note: "paseo"),
            PlannedDay(weekday: 4, sessionId: deleted)
        ]).toDTO()

        let logUseCase = FakeWorkoutLogUseCase()
        logUseCase.sessions = [WorkoutSession(id: push, name: "Empuje")]

        let useCase = WeeklyPlanUseCase(
            repository: WeeklyPlanRepository(
                local: local, remote: remote, session: StubSession(authenticated: false)
            ),
            workoutLogUseCase: logUseCase
        )

        let week = try await useCase.getResolvedWeek()
        XCTAssertEqual(week.map(\.weekday), [2, 3, 4])
        XCTAssertEqual(week[0].session?.name, "Empuje")
        XCTAssertTrue(week[1].isRest)
        XCTAssertEqual(week[1].note, "paseo")
        // La sesión borrada no se disimula como descanso: hay que poder arreglarlo.
        XCTAssertTrue(week[2].isMissingSession)
        XCTAssertFalse(week[2].isRest)
    }

    /// No poder leer el catálogo de sesiones no puede dejar sin plan: se enseña con
    /// los nombres a medias, que es más que nada.
    func testResolvedWeekSurvivesSessionLookupFailure() async throws {
        let local = FakeLocal()
        local.plan = WeeklyPlan(name: "Fuerza", days: [
            PlannedDay(weekday: 2, sessionId: UUID())
        ]).toDTO()

        let logUseCase = FakeWorkoutLogUseCase()
        logUseCase.failsOnSessions = true

        let useCase = WeeklyPlanUseCase(
            repository: WeeklyPlanRepository(
                local: local, remote: FakeRemote(), session: StubSession(authenticated: false)
            ),
            workoutLogUseCase: logUseCase
        )

        let week = try await useCase.getResolvedWeek()
        XCTAssertEqual(week.count, 1)
        XCTAssertTrue(week[0].isMissingSession)
    }

    // MARK: - Persistencia

    /// Un `weekday` fuera de rango no debe llegar al dominio: pedir su nombre
    /// indexaría fuera del array de símbolos del calendario.
    func testOutOfRangeWeekdaysAreDroppedOnRead() {
        let dto = WeeklyPlanDTO(name: "Roto", days: [
            .init(weekday: 0, sessionId: nil, note: nil),
            .init(weekday: 8, sessionId: nil, note: nil),
            .init(weekday: 2, sessionId: nil, note: nil)
        ])
        XCTAssertEqual(dto.toDomain().days.map(\.weekday), [2])
    }

    func testWeekdayNameIsEmptyForOutOfRange() {
        XCTAssertEqual(WeeklyPlan.weekdayName(0), "")
        XCTAssertEqual(WeeklyPlan.weekdayName(8), "")
        XCTAssertFalse(WeeklyPlan.weekdayName(2).isEmpty)
    }
}
