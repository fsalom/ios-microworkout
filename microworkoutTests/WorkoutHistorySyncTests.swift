import XCTest
// `NetworkError` es de TripleA: los dobles lo usan para simular el 404 del
// servidor, que el repositorio trata distinto de un fallo de red.
import TripleA
@testable import microworkout

/// Los entrenos hechos como invitado desaparecían al iniciar sesión: la lectura
/// pasaba a ser solo-servidor, así que lo que seguía guardado en el dispositivo
/// dejaba de verse. Y, ya con sesión, un fallo del servidor al guardar se tragaba
/// el entreno recién hecho, porque todos los llamantes usan `try?`.
///
/// Mismo planteamiento que `MealFavoritesSyncTests`: la sesión se INYECTA en el
/// repositorio en vez de tocar `AuthSession.shared`, que lo comparte toda la suite.
final class WorkoutHistorySyncTests: XCTestCase {

    // MARK: - Dobles

    private enum Fake: Error { case offline, notFound, unused }

    private final class FakeLogLocal: WorkoutLogLocalDataSourceProtocol {
        var sessions: [WorkoutSessionDTO] = []
        var logs: [WorkoutLogDTO] = []

        func getAllSessions() -> [WorkoutSessionDTO] { sessions }
        func saveSession(_ session: WorkoutSessionDTO) {
            sessions.removeAll { $0.id == session.id }
            sessions.append(session)
        }
        func deleteSession(id: String) { sessions.removeAll { $0.id.uuidString == id } }

        func getAllLogs() -> [WorkoutLogDTO] { logs }
        func saveLog(_ log: WorkoutLogDTO) {
            logs.removeAll { $0.id == log.id }
            logs.append(log)
        }
        func deleteLog(id: String) { logs.removeAll { $0.id.uuidString == id } }
    }

    private final class FakeLogRemote: WorkoutLogRemoteDataSourceProtocol {
        var sessions: [WorkoutSessionApiDTO] = []
        var logs: [WorkoutLogApiDTO] = []
        /// Simula servidor caído en las escrituras y lecturas.
        var isOffline = false
        /// Ids que el servidor dice no conocer al borrar.
        var unknownOnDelete: Set<UUID> = []
        private(set) var upsertedLogIds: [UUID] = []
        private(set) var deletedLogIds: [UUID] = []

        func listSessions() async throws -> [WorkoutSessionApiDTO] {
            if isOffline { throw Fake.offline }
            return sessions
        }

        func upsertSession(_ session: WorkoutSession) async throws -> WorkoutSessionApiDTO {
            if isOffline { throw Fake.offline }
            let dto = WorkoutSessionApiDTO(
                id: session.id, name: session.name, exercises: [],
                createdAt: session.createdAt, updatedAt: session.updatedAt
            )
            sessions.removeAll { $0.id == dto.id }
            sessions.append(dto)
            return dto
        }

        func deleteSession(id: UUID) async throws {
            if unknownOnDelete.contains(id) { throw NetworkError.failure(statusCode: 404, data: nil, response: nil) }
            if isOffline { throw Fake.offline }
            sessions.removeAll { $0.id == id }
        }

        func listLogs() async throws -> [WorkoutLogApiDTO] {
            if isOffline { throw Fake.offline }
            return logs
        }

        func upsertLog(_ log: WorkoutLog) async throws -> WorkoutLogApiDTO {
            if isOffline { throw Fake.offline }
            upsertedLogIds.append(log.id)
            let dto = WorkoutLogApiDTO(
                id: log.id, sessionId: log.sessionId, sessionName: log.sessionName,
                startedAt: log.startedAt, endedAt: log.endedAt,
                linkedHealthWorkoutId: nil, exercises: []
            )
            logs.removeAll { $0.id == dto.id }
            logs.append(dto)
            return dto
        }

        func deleteLog(id: UUID) async throws {
            if unknownOnDelete.contains(id) { throw NetworkError.failure(statusCode: 404, data: nil, response: nil) }
            if isOffline { throw Fake.offline }
            deletedLogIds.append(id)
            logs.removeAll { $0.id == id }
        }
    }

    private final class FakeTrainingLocal: TrainingLocalDataSourceProtocol {
        var current: TrainingDTO?
        var finished: [TrainingDTO] = []

        func getCurrent() -> TrainingDTO? { current }
        func saveCurrent(_ training: TrainingDTO) { current = training }
        func finish(_ training: TrainingDTO) {
            finished.append(training)
            current = nil
        }
        func getFinished() -> [TrainingDTO] { finished }
        func clearCurrent() { current = nil }
        func clearFinished() { finished = [] }
    }

    private final class FakeTrainingRemote: TrainingRemoteDataSourceProtocol {
        var all: [TrainingApiDTO] = []
        var finished: [TrainingApiDTO] = []
        var currentTraining: TrainingApiDTO?
        var isOffline = false
        private(set) var finishedCalls: [UUID] = []

        func list() async throws -> [TrainingApiDTO] {
            if isOffline { throw Fake.offline }
            return all
        }
        func listFinished() async throws -> [TrainingApiDTO] {
            if isOffline { throw Fake.offline }
            return finished
        }
        func current() async throws -> TrainingApiDTO? {
            if isOffline { throw Fake.offline }
            return currentTraining
        }
        func saveCurrent(_ training: Training) async throws -> TrainingApiDTO {
            if isOffline { throw Fake.offline }
            return apiDTO(training)
        }
        func finish(_ training: Training) async throws -> TrainingApiDTO {
            if isOffline { throw Fake.offline }
            finishedCalls.append(training.id)
            return apiDTO(training)
        }

        private func apiDTO(_ training: Training) -> TrainingApiDTO {
            TrainingApiDTO(
                id: training.id, name: training.name, image: training.image,
                type: training.type.rawValue, numberOfSets: 0, numberOfReps: 0,
                numberOfMinutesPerSet: 0, startedAt: training.startedAt,
                completedAt: training.completedAt, sets: [],
                numberOfSetsCompleted: 0, numberOfSeconds: 0
            )
        }
    }

    // MARK: - Utilidades
    /// Sesión propia del test. Antes se cambiaba `AuthSession.shared`, que es un
    /// singleton compartido por toda la suite: con los tests corriendo en PARALELO,
    /// un test que la cambiaba hacía fallar a otro que se ejecutaba a la vez, y el
    /// fallo salía en la clase equivocada.
    private struct StubSession: AuthStateProviding {
        let authenticated: Bool
        var isAuthenticated: Bool { get async { authenticated } }
    }


    private func sessionDTO(_ id: UUID, _ name: String) -> WorkoutSessionDTO {
        WorkoutSessionDTO(
            id: id, name: name, exerciseIds: [], exerciseNames: [], exerciseTypes: [],
            createdAt: Date(timeIntervalSince1970: 0), updatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func logDTO(_ id: UUID, _ name: String, at date: Date) -> WorkoutLogDTO {
        WorkoutLogDTO(
            id: id, sessionId: nil, sessionName: name, startedAt: date,
            endedAt: nil, exercises: [], linkedHealthWorkoutId: nil
        )
    }

    private func trainingDTO(_ id: UUID, _ name: String, completedAt: Date?) -> TrainingDTO {
        TrainingDTO(
            id: id, name: name, image: "push-up-1", type: TrainingType.strength.rawValue,
            startedAt: completedAt, completedAt: completedAt,
            numberOfSets: 3, numberOfReps: 10, numberOfMinutesPerSet: 1
        )
    }

    private func finishedApiDTO(_ id: UUID, _ name: String, completedAt: Date) -> TrainingApiDTO {
        TrainingApiDTO(
            id: id, name: name, image: "push-up-1", type: TrainingType.strength.rawValue,
            numberOfSets: 3, numberOfReps: 10, numberOfMinutesPerSet: 1,
            startedAt: completedAt, completedAt: completedAt, sets: [],
            numberOfSetsCompleted: 3, numberOfSeconds: 0
        )
    }

    // MARK: - Sesiones y registros de gimnasio

    func testGuestSessionsRemainVisibleAfterLogin() async throws {
        let local = FakeLogLocal()
        local.sessions = [sessionDTO(UUID(), "Torso de invitado")]
        let remote = FakeLogRemote()
        remote.sessions = [
            WorkoutSessionApiDTO(id: UUID(), name: "Pierna de la cuenta", exercises: [],
                                 createdAt: Date(), updatedAt: Date())
        ]
        let repository = WorkoutLogRepository(local: local, remote: remote, session: StubSession(authenticated: true))

        let result = try await repository.getAllSessions()
        XCTAssertEqual(
            Set(result.map(\.name)), ["Pierna de la cuenta", "Torso de invitado"],
            "las sesiones de invitado deben convivir con las de la cuenta"
        )
    }

    func testSyncedSessionIsNotDuplicated() async throws {
        let shared = UUID()
        let local = FakeLogLocal()
        local.sessions = [sessionDTO(shared, "Torso")]
        let remote = FakeLogRemote()
        remote.sessions = [
            WorkoutSessionApiDTO(id: shared, name: "Torso", exercises: [],
                                 createdAt: Date(), updatedAt: Date())
        ]
        let repository = WorkoutLogRepository(local: local, remote: remote, session: StubSession(authenticated: true))

        let result = try await repository.getAllSessions()
        XCTAssertEqual(result.count, 1, "la copia local ya subida no debe salir dos veces")
    }

    func testServerFailureDoesNotHideLocalLogs() async throws {
        let local = FakeLogLocal()
        local.logs = [logDTO(UUID(), "Torso", at: Date())]
        let remote = FakeLogRemote()
        remote.isOffline = true
        let repository = WorkoutLogRepository(local: local, remote: remote, session: StubSession(authenticated: true))

        let result = try await repository.getAllLogs()
        XCTAssertEqual(result.count, 1, "si el servidor falla se muestra lo local, no una lista vacía")
    }

    func testLogsComeBackNewestFirst() async throws {
        let old = Date(timeIntervalSince1970: 1_000)
        let recent = Date(timeIntervalSince1970: 9_000)
        let local = FakeLogLocal()
        local.logs = [logDTO(UUID(), "Local reciente", at: recent)]
        let remote = FakeLogRemote()
        remote.logs = [
            WorkoutLogApiDTO(id: UUID(), sessionId: nil, sessionName: "Servidor antiguo",
                             startedAt: old, endedAt: nil, linkedHealthWorkoutId: nil, exercises: [])
        ]
        let repository = WorkoutLogRepository(local: local, remote: remote, session: StubSession(authenticated: true))

        let result = try await repository.getAllLogs()
        XCTAssertEqual(result.map(\.sessionName), ["Local reciente", "Servidor antiguo"])
    }

    func testLogSurvivesWhenTheServerIsDown() async throws {
        let local = FakeLogLocal()
        let remote = FakeLogRemote()
        remote.isOffline = true
        let repository = WorkoutLogRepository(local: local, remote: remote, session: StubSession(authenticated: true))
        let log = WorkoutLog(
            id: UUID(), sessionId: nil, sessionName: "Torso", startedAt: Date(),
            endedAt: nil, exercises: [], linkedHealthWorkoutId: nil
        )

        try await repository.saveLog(log)
        XCTAssertEqual(local.logs.count, 1, "el entreno debe quedar en el dispositivo, no perderse")

        // Y cuando vuelve la conexión, la sincronización sabe que falta por subir.
        remote.isOffline = false
        let pending = try await repository.pendingSyncCount()
        XCTAssertEqual(pending, 1, "queda contado como pendiente hasta que se suba")
    }

    func testLogSavedOfflineIsUploadedLater() async throws {
        let local = FakeLogLocal()
        let remote = FakeLogRemote()
        remote.isOffline = true
        let repository = WorkoutLogRepository(local: local, remote: remote, session: StubSession(authenticated: true))
        let log = WorkoutLog(
            id: UUID(), sessionId: nil, sessionName: "Torso", startedAt: Date(),
            endedAt: nil, exercises: [], linkedHealthWorkoutId: nil
        )

        try await repository.saveLog(log)
        remote.isOffline = false
        let uploaded = try await repository.syncLocalToRemote()
        XCTAssertEqual(uploaded, 1)
        XCTAssertEqual(remote.upsertedLogIds, [log.id])
    }

    func testDeletingALocalOnlyLogDoesNotFail() async throws {
        let id = UUID()
        let local = FakeLogLocal()
        local.logs = [logDTO(id, "Torso", at: Date())]
        let remote = FakeLogRemote()
        remote.unknownOnDelete = [id]
        let repository = WorkoutLogRepository(local: local, remote: remote, session: StubSession(authenticated: true))

        try await repository.deleteLog(id: id.uuidString)
        XCTAssertTrue(local.logs.isEmpty, "un 404 del servidor no debe impedir borrarlo del dispositivo")
    }

    func testDeleteIsNotAssumedWhenTheServerIsUnreachable() async throws {
        let id = UUID()
        let local = FakeLogLocal()
        local.logs = [logDTO(id, "Torso", at: Date())]
        let remote = FakeLogRemote()
        remote.isOffline = true
        let repository = WorkoutLogRepository(local: local, remote: remote, session: StubSession(authenticated: true))

        do {
            try await repository.deleteLog(id: id.uuidString)
            XCTFail("sin servidor el borrado no se puede dar por hecho")
        } catch {
            XCTAssertEqual(local.logs.count, 1, "la copia local se conserva hasta poder borrar en el servidor")
        }
    }

    // MARK: - Micro-entrenos terminados

    func testGuestFinishedTrainingsRemainVisibleAfterLogin() async throws {
        let local = FakeTrainingLocal()
        local.finished = [trainingDTO(UUID(), "Flexiones de invitado", completedAt: Date(timeIntervalSince1970: 500))]
        let remote = FakeTrainingRemote()
        remote.finished = [finishedApiDTO(UUID(), "Dominadas de la cuenta", completedAt: Date(timeIntervalSince1970: 900))]
        let repository = TrainingRepository(local: local, remote: remote, session: StubSession(authenticated: true))

        let result = try await repository.getFinished()
        XCTAssertEqual(
            Set(result.map(\.name)), ["Flexiones de invitado", "Dominadas de la cuenta"],
            "el historial de invitado no puede desaparecer al entrar en la cuenta"
        )
    }

    /// El caso que rompería un dedup ingenuo: al empezar un preset se conserva su
    /// UUID, así que dos "Flexiones" comparten id y solo las distingue la fecha.
    func testRepeatingThePresetKeepsEveryRunInTheHistory() async throws {
        let presetId = UUID()
        let firstRun = Date(timeIntervalSince1970: 1_000)
        let secondRun = Date(timeIntervalSince1970: 2_000)
        let local = FakeTrainingLocal()
        local.finished = [
            trainingDTO(presetId, "Flexiones", completedAt: firstRun),
            trainingDTO(presetId, "Flexiones", completedAt: secondRun),
        ]
        let remote = FakeTrainingRemote()
        remote.finished = [finishedApiDTO(presetId, "Flexiones", completedAt: secondRun)]
        let repository = TrainingRepository(local: local, remote: remote, session: StubSession(authenticated: true))

        let result = try await repository.getFinished()
        XCTAssertEqual(result.count, 2, "la serie subida no debe borrar del historial las otras del mismo preset")
        XCTAssertEqual(result.map { $0.completedAt }, [secondRun, firstRun], "más reciente primero")
    }

    func testFinishedTrainingSurvivesWhenTheServerIsDown() async throws {
        let local = FakeTrainingLocal()
        let remote = FakeTrainingRemote()
        remote.isOffline = true
        let repository = TrainingRepository(local: local, remote: remote, session: StubSession(authenticated: false))
        var training = Training(name: "Flexiones", image: "push-up-1", type: .strength,
                                numberOfSetsForSlider: 3, numberOfRepsForSlider: 10,
                                numberOfMinutesPerSetForSlider: 1)
        training.completedAt = Date()

        try await repository.finish(training)
        XCTAssertEqual(local.finished.count, 1, "lo entrenado se guarda en el dispositivo aunque falle el servidor")
        let result = try await repository.getFinished()
        XCTAssertEqual(result.count, 1, "y se sigue viendo en el historial")
    }

    func testNoCurrentTrainingOnTheServerDoesNotResurrectTheLocalOne() async throws {
        let local = FakeTrainingLocal()
        local.current = trainingDTO(UUID(), "Flexiones ya terminadas en otro sitio", completedAt: nil)
        let remote = FakeTrainingRemote()
        remote.currentTraining = nil
        let repository = TrainingRepository(local: local, remote: remote, session: StubSession(authenticated: true))

        let current = try await repository.getCurrent()
        XCTAssertNil(current, "que el servidor diga que no hay ninguno es una respuesta, no un fallo")
    }

    func testCurrentTrainingFallsBackToLocalWhenTheServerFails() async throws {
        let local = FakeTrainingLocal()
        local.current = trainingDTO(UUID(), "Flexiones en curso", completedAt: nil)
        let remote = FakeTrainingRemote()
        remote.isOffline = true
        let repository = TrainingRepository(local: local, remote: remote, session: StubSession(authenticated: true))

        let current = try await repository.getCurrent()
        XCTAssertEqual(current?.name, "Flexiones en curso", "sin servidor, el del dispositivo es el que hay")
    }

    func testGuestModeNeverTouchesTheServer() async throws {
        let local = FakeTrainingLocal()
        let remote = FakeTrainingRemote()
        remote.isOffline = true   // cualquier llamada al servidor haría fallar el test
        let repository = TrainingRepository(local: local, remote: remote, session: StubSession(authenticated: false))
        var training = Training(name: "Flexiones", image: "push-up-1", type: .strength,
                                numberOfSetsForSlider: 3, numberOfRepsForSlider: 10,
                                numberOfMinutesPerSetForSlider: 1)
        training.completedAt = Date()

        try await repository.finish(training)
        let result = try await repository.getFinished()
        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(remote.finishedCalls.isEmpty)
    }
}
