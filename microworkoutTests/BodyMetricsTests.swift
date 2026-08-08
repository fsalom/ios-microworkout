import XCTest
@testable import microworkout

/// El peso vive en tres sitios (Apple Salud, dispositivo, cuenta) y la regla de
/// quién gana es lo único que evita que el usuario vea dos pesos distintos del
/// mismo día. Estos tests fijan esa regla y el contrato de fechas con el backend,
/// que es donde se rompen estas cosas.
final class BodyMetricsTests: XCTestCase {

    // MARK: - Dobles

    private enum Fake: Error { case offline, denied }

    private final class FakeHealth: HealthRepositoryProtocol {
        var available = true
        var byDay: [Date: Double] = [:]
        var failsOnRead = false
        var failsOnWrite = false
        private(set) var saved: [(kg: Double, date: Date)] = []

        var isHealthDataAvailable: Bool { available }
        var authorizationStatus: HealthAuthorizationStatus { .authorized }
        func requestAuthorization() async throws -> Bool { true }
        func fetchExerciseTimeToday() async throws -> Double? { nil }
        func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date: Double]? { nil }
        func fetchStepsCountToday() async throws -> Double? { nil }
        func fetchStepsCount(startDate: Date, endDate: Date) async throws -> [Date: Double]? { stepsByDay }
        func fetchStandingTime() async throws -> Double? { nil }
        func fetchStandingTime(startDate: Date, endDate: Date) async throws -> [Date: Double]? { nil }
        func fetchWorkouts() async throws -> [HealthWorkout] { [] }

        func fetchBodyMass(startDate: Date, endDate: Date) async throws -> [Date: Double] {
            if failsOnRead { throw Fake.denied }
            return byDay
        }

        /// Series de actividad. `stepsFails` aparte para poder comprobar que un
        /// permiso denegado en UNA métrica no se lleva por delante las demás.
        var stepsByDay: [Date: Double] = [:]
        var energyByDay: [Date: Double] = [:]
        var restingByDay: [Date: Double] = [:]
        var restingFails = false

        func fetchActiveEnergy(startDate: Date, endDate: Date) async throws -> [Date: Double] {
            energyByDay
        }

        func fetchRestingHeartRate(startDate: Date, endDate: Date) async throws -> [Date: Double] {
            if restingFails { throw Fake.denied }
            return restingByDay
        }

        func saveBodyMass(kilograms: Double, on date: Date) async throws {
            if failsOnWrite { throw Fake.denied }
            saved.append((kilograms, date))
        }
    }

    /// Réplica de `BodyMetricsLocalDataSource`, lápidas incluidas: si el doble
    /// olvidara recordar los días borrados, los tests pasarían contra un
    /// comportamiento que la app real no tiene.
    private final class FakeLocal: BodyMetricsLocalDataSourceProtocol {
        var stored: [DailyMetricsDTO] = []
        var deleted: Set<Date> = []
        func getAll() -> [DailyMetricsDTO] { stored }
        func save(_ measurement: DailyMetricsDTO) {
            stored.removeAll { Calendar.current.isDate($0.date, inSameDayAs: measurement.date) }
            stored.append(measurement)
            deleted.remove(Calendar.current.startOfDay(for: measurement.date))
        }
        func delete(date: Date) {
            stored.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
            deleted.insert(Calendar.current.startOfDay(for: date))
        }
        func deletedDates() -> Set<Date> { deleted }
    }

    private final class FakeRemote: BodyMetricsRemoteDataSourceProtocol {
        var stored: [DailyMetrics] = []
        var isOffline = false
        private(set) var bulkCalls = 0
        private(set) var upsertCalls = 0

        func list(from start: Date?, to end: Date?) async throws -> [DailyMetricsApiDTO] {
            if isOffline { throw Fake.offline }
            // El doble devuelve entidades ya mapeadas: lo que se prueba aquí es la
            // fusión, no el JSON (eso lo cubre `testDateContract`).
            return try stored.map { try Self.dto(from: $0) }
        }

        func upsert(_ measurement: DailyMetrics) async throws -> DailyMetricsApiDTO {
            if isOffline { throw Fake.offline }
            upsertCalls += 1
            stored.removeAll { $0.date == measurement.date }
            stored.append(measurement)
            return try Self.dto(from: measurement)
        }

        func upsertMany(_ measurements: [DailyMetrics]) async throws -> Int {
            if isOffline { throw Fake.offline }
            bulkCalls += 1
            for measurement in measurements {
                stored.removeAll { $0.date == measurement.date }
                stored.append(measurement)
            }
            return measurements.count
        }

        func delete(date: Date) async throws {
            if isOffline { throw Fake.offline }
            stored.removeAll { $0.date == date }
        }

        /// Construye el DTO pasando por JSON, así el doble no puede divergir del
        /// formato real de la API.
        static func dto(from measurement: DailyMetrics) throws -> DailyMetricsApiDTO {
            var json: [String: Any] = [
                "date": BodyMetricsDateFormat.day.string(from: measurement.date),
                "source": measurement.source.rawValue,
            ]
            if let weight = measurement.weightKg { json["weight_kg"] = weight }
            if let steps = measurement.steps { json["steps"] = steps }
            if let kcal = measurement.activeKcal { json["active_kcal"] = kcal }
            if let hr = measurement.restingHeartRate { json["resting_heart_rate"] = hr }
            let data = try JSONSerialization.data(withJSONObject: json)
            return try JSONDecoder().decode(DailyMetricsApiDTO.self, from: data)
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


    private func day(_ offset: Int) -> Date {
        Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        )
    }


    private func makeRepository(
        health: FakeHealth = FakeHealth(),
        local: FakeLocal = FakeLocal(),
        remote: FakeRemote = FakeRemote(),
        authenticated: Bool = true
    ) -> BodyMetricsRepository {
        BodyMetricsRepository(
            health: health, local: local, remote: remote,
            session: StubSession(authenticated: authenticated)
        )
    }

    // MARK: - Quién gana

    func testHealthWinsOverTheAccountForTheSameDay() async throws {
        let health = FakeHealth()
        health.byDay = [day(0): 79.5]
        let remote = FakeRemote()
        remote.stored = [DailyMetrics(date: day(0), weightKg: 80.0, source: .manual)]
        let repository = makeRepository(health: health, remote: remote)

        let result = try await repository.getMeasurements(from: day(-7), to: day(0))
        XCTAssertEqual(result.count, 1, "un día, una medida")
        XCTAssertEqual(result.first?.weightKg, 79.5, "Salud es la fuente: manda su valor")
    }

    func testDeniedHealthDoesNotHideTheOtherSources() async throws {
        let health = FakeHealth()
        health.failsOnRead = true
        let local = FakeLocal()
        local.stored = [DailyMetrics(date: day(-1), weightKg: 81.0).toDTO()]
        let repository = makeRepository(health: health, local: local, authenticated: false)

        let result = try await repository.getMeasurements(from: day(-7), to: day(0))
        XCTAssertEqual(result.first?.weightKg, 81.0, "sin permiso de Salud se sigue viendo lo del dispositivo")
    }

    func testServerFailureDoesNotHideLocalWeights() async throws {
        let local = FakeLocal()
        local.stored = [DailyMetrics(date: day(-2), weightKg: 77.0).toDTO()]
        let remote = FakeRemote()
        remote.isOffline = true
        let repository = makeRepository(local: local, remote: remote)

        let result = try await repository.getMeasurements(from: day(-7), to: day(0))
        XCTAssertEqual(result.count, 1, "una caída del servidor no puede vaciar la gráfica")
    }

    // MARK: - Anotar

    func testSavingWritesToHealthAndTheAccount() async throws {
        let health = FakeHealth()
        let local = FakeLocal()
        let remote = FakeRemote()
        let repository = makeRepository(health: health, local: local, remote: remote)

        try await repository.saveWeight(78.4, on: day(0))
        XCTAssertEqual(health.saved.first?.kg, 78.4, "lo anotado tiene que acabar en Salud")
        XCTAssertEqual(local.stored.count, 1, "y en el dispositivo")
        XCTAssertEqual(remote.upsertCalls, 1, "y en la cuenta")
    }

    func testWeightSurvivesWhenHealthAndServerBothFail() async throws {
        let health = FakeHealth()
        health.failsOnWrite = true
        let local = FakeLocal()
        let remote = FakeRemote()
        remote.isOffline = true
        let repository = makeRepository(health: health, local: local, remote: remote)

        try await repository.saveWeight(78.4, on: day(0))
        XCTAssertEqual(local.stored.first?.weightKg, 78.4, "el dato no se pierde por que fallen los otros dos")
    }

    func testDeletingDoesNotTouchAppleHealth() async throws {
        let health = FakeHealth()
        health.byDay = [day(0): 79.5]
        let local = FakeLocal()
        local.stored = [DailyMetrics(date: day(0), weightKg: 79.5).toDTO()]
        let repository = makeRepository(health: health, local: local)

        try await repository.delete(date: day(0))
        XCTAssertTrue(local.stored.isEmpty, "se borra del dispositivo")
        XCTAssertEqual(health.byDay.count, 1, "pero NO de Salud: esos datos son del usuario")
    }

    func testGuestModeNeverCallsTheServer() async throws {
        let health = FakeHealth()
        let local = FakeLocal()
        let remote = FakeRemote()
        remote.isOffline = true   // cualquier llamada haría fallar el test
        let repository = makeRepository(health: health, local: local, remote: remote, authenticated: false)

        try await repository.saveWeight(78.4, on: day(0))
        XCTAssertEqual(local.stored.count, 1)
        XCTAssertEqual(remote.upsertCalls, 0)
    }

    // MARK: - Sincronización

    func testSyncUploadsWhatTheAccountIsMissing() async throws {
        let health = FakeHealth()
        health.byDay = [day(-1): 80.0, day(-2): 80.5]
        let local = FakeLocal()
        local.stored = [DailyMetrics(date: day(-3), weightKg: 81.0).toDTO()]
        let remote = FakeRemote()
        remote.stored = [DailyMetrics(date: day(-1), weightKg: 80.0, source: .health)]
        let repository = makeRepository(health: health, local: local, remote: remote)

        let pending = try await repository.pendingSyncCount()
        XCTAssertEqual(pending, 2, "faltan los dos días que no están en la cuenta")
        let uploaded = try await repository.syncLocalToRemote()
        XCTAssertEqual(uploaded, 2)
        XCTAssertEqual(remote.bulkCalls, 1, "en una sola petición, no una por día")
        let remaining = try await repository.pendingSyncCount()
        XCTAssertEqual(remaining, 0)
    }

    // MARK: - Borrado

    /// Borrar un peso tiene que durar más que hasta la siguiente lectura.
    ///
    /// Quitarlo solo del dispositivo no bastaba: Apple Salud conserva la muestra
    /// —la escribió la báscula, otra app, o esta misma al anotar el peso— y
    /// `getMeasurements` la volvía a traer. El usuario borraba, la fila desaparecía
    /// por el borrado optimista de la pantalla, y reaparecía al volver a entrar.
    func testDeletingADayDoesNotBringItBackFromHealth() async throws {
        let health = FakeHealth()
        health.byDay = [day(-1): 80.0, day(0): 79.5]
        let repository = makeRepository(health: health, authenticated: false)

        try await repository.delete(date: day(-1))

        let result = try await repository.getMeasurements(from: day(-7), to: day(0))
        XCTAssertEqual(result.map { $0.date }, [day(0)], "el día borrado no puede volver de Salud")
    }

    /// Y tampoco puede resucitar por la puerta de atrás: si sigue contándose como
    /// pendiente, la siguiente sincronización lo vuelve a subir a la cuenta y
    /// borrarlo allí no habrá servido de nada.
    func testADeletedDayIsNotUploadedAgain() async throws {
        let health = FakeHealth()
        health.byDay = [day(-1): 80.0]
        let remote = FakeRemote()
        let repository = makeRepository(health: health, remote: remote)

        try await repository.delete(date: day(-1))

        let pending = try await repository.pendingSyncCount()
        let uploaded = try await repository.syncLocalToRemote()
        XCTAssertEqual(pending, 0)
        XCTAssertEqual(uploaded, 0)
        XCTAssertTrue(remote.stored.isEmpty, "no se resube lo que el usuario borró")
    }

    func testWeighingAgainOnADeletedDayBringsItBack() async throws {
        let repository = makeRepository(authenticated: false)

        try await repository.saveWeight(80.0, on: day(-1))
        try await repository.delete(date: day(-1))
        try await repository.saveWeight(78.0, on: day(-1))

        let result = try await repository.getMeasurements(from: day(-7), to: day(0))
        XCTAssertEqual(
            result.map { $0.weightKg }, [78.0],
            "la lápida es del borrado concreto, no del día: volver a pesarse lo revive"
        )
    }

    /// La lápida solo vive en el dispositivo que borró. Si el borrado no llegó al
    /// servidor (sin red), hay que rematarlo en la siguiente sincronización o el
    /// día sigue en la cuenta y reaparece desde otro móvil.
    func testADeleteThatNeverReachedTheAccountIsRetriedOnSync() async throws {
        let measurement = DailyMetrics(date: day(-1), weightKg: 80.0, source: .manual)
        let local = FakeLocal()
        local.stored = [measurement.toDTO()]
        let remote = FakeRemote()
        remote.stored = [measurement]
        let repository = makeRepository(local: local, remote: remote)

        remote.isOffline = true
        try await repository.delete(date: day(-1))
        remote.isOffline = false

        let pending = try await repository.pendingSyncCount()
        XCTAssertEqual(pending, 1, "un borrado que no llegó a la cuenta también es trabajo pendiente")
        _ = try await repository.syncLocalToRemote()
        XCTAssertTrue(remote.stored.isEmpty, "la sincronización remata el borrado")
    }

    // MARK: - Tendencia

    func testTrendNeedsTwoMeasurements() {
        XCTAssertNil(
            WeightTrend.from([DailyMetrics(date: day(0), weightKg: 80)]),
            "una sola medida no es una tendencia"
        )
    }

    func testTrendComputesDeltaAndWeeklyRate() throws {
        let trend = try XCTUnwrap(WeightTrend.from([
            DailyMetrics(date: day(-28), weightKg: 82.0),
            DailyMetrics(date: day(-14), weightKg: 81.0),
            DailyMetrics(date: day(0), weightKg: 79.5),
        ]))
        XCTAssertEqual(trend.deltaKg, -2.5)
        XCTAssertEqual(trend.days, 28)
        XCTAssertEqual(trend.kgPerWeek, -0.63)
    }

    func testWeeklyRateIsNilBelowAWeek() throws {
        let trend = try XCTUnwrap(WeightTrend.from([
            DailyMetrics(date: day(-2), weightKg: 80.0),
            DailyMetrics(date: day(0), weightKg: 79.6),
        ]))
        XCTAssertNil(trend.kgPerWeek, "con dos días no se puede extrapolar un ritmo semanal")
    }

    // MARK: - Contrato con el backend

    /// El backend manda la fecha como día suelto (`2026-08-01`). Decodificarla con
    /// el decodificador ISO del resto de DTOs falla, así que este test es el que
    /// avisa si alguien "unifica" el formato.
    func testDateContract() throws {
        let json = """
        {"date": "2026-08-01", "weight_kg": 78.4, "body_fat_percentage": null, "source": "health"}
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(DailyMetricsApiDTO.self, from: json)
        let measurement = dto.toDomain()

        var components = DateComponents()
        components.year = 2026; components.month = 8; components.day = 1
        XCTAssertEqual(measurement.date, Calendar.current.date(from: components))
        XCTAssertEqual(measurement.weightKg, 78.4)
        XCTAssertEqual(measurement.source, .health)
    }

    func testUnknownSourceIsTreatedAsManual() throws {
        let json = """
        {"date": "2026-08-01", "weight_kg": 78.4, "source": "bascula-nueva"}
        """.data(using: .utf8)!
        let dto = try JSONDecoder().decode(DailyMetricsApiDTO.self, from: json)
        XCTAssertEqual(dto.toDomain().source, .manual, "una fuente desconocida no puede reventar el decodificado")
    }

    func testMeasurementNormalizesToStartOfDay() {
        let noon = Calendar.current.date(bySettingHour: 13, minute: 27, second: 0, of: Date())!
        let measurement = DailyMetrics(date: noon, weightKg: 80)
        XCTAssertEqual(measurement.date, Calendar.current.startOfDay(for: noon),
                       "la identidad de una medida es el día, no el instante")
    }

    // MARK: - Varias métricas por día

    func testHealthMetricsAreMergedIntoOneDay() async throws {
        let health = FakeHealth()
        health.byDay = [day(0): 79.5]
        health.stepsByDay = [day(0): 9500]
        health.energyByDay = [day(0): 610]
        health.restingByDay = [day(0): 52]
        let repository = makeRepository(health: health)

        let result = try await repository.getMeasurements(from: day(-7), to: day(0))
        XCTAssertEqual(result.count, 1, "todo lo del mismo día va en un registro")
        XCTAssertEqual(result.first?.weightKg, 79.5)
        XCTAssertEqual(result.first?.steps, 9500)
        XCTAssertEqual(result.first?.activeKcal, 610)
        XCTAssertEqual(result.first?.restingHeartRate, 52)
    }

    func testOneDeniedMetricDoesNotLoseTheRest() async throws {
        let health = FakeHealth()
        health.stepsByDay = [day(0): 9500]
        health.restingFails = true
        let repository = makeRepository(health: health)

        let result = try await repository.getMeasurements(from: day(-7), to: day(0))
        XCTAssertEqual(result.first?.steps, 9500, "sin permiso de FC se siguen viendo los pasos")
        XCTAssertNil(result.first?.restingHeartRate)
    }

    /// El caso que rompería una fusión que reemplaza el registro entero: la cuenta
    /// tiene el peso (que vino de otro móvil) y Salud tiene los pasos de aquí.
    func testAccountWeightAndPhoneStepsCoexist() async throws {
        let health = FakeHealth()
        health.stepsByDay = [day(-1): 12000]
        let remote = FakeRemote()
        remote.stored = [DailyMetrics(date: day(-1), weightKg: 80.0, source: .manual)]
        let repository = makeRepository(health: health, remote: remote)

        let result = try await repository.getMeasurements(from: day(-7), to: day(0))
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.weightKg, 80.0, "el peso de la cuenta no se pierde")
        XCTAssertEqual(result.first?.steps, 12000, "y los pasos del móvil tampoco")
    }

    func testDayAlreadyInTheAccountStillUploadsTheMissingMetrics() async throws {
        let health = FakeHealth()
        health.stepsByDay = [day(-1): 12000]
        let remote = FakeRemote()
        remote.stored = [DailyMetrics(date: day(-1), weightKg: 80.0, source: .manual)]
        let repository = makeRepository(health: health, remote: remote)

        let pending = try await repository.pendingSyncCount()
        XCTAssertEqual(pending, 1, "el día está, pero le faltan los pasos")
        let uploaded = try await repository.syncLocalToRemote()
        XCTAssertEqual(uploaded, 1)
        let remaining = try await repository.pendingSyncCount()
        XCTAssertEqual(remaining, 0, "y despues de subirlos ya no falta nada")
    }

    func testNothingNewIsNotUploadedAgain() async throws {
        let health = FakeHealth()
        health.stepsByDay = [day(-1): 12000]
        let remote = FakeRemote()
        remote.stored = [DailyMetrics(date: day(-1), steps: 12000, source: .health)]
        let repository = makeRepository(health: health, remote: remote)

        let pending = try await repository.pendingSyncCount()
        XCTAssertEqual(pending, 0, "lo que ya está en la cuenta no se reenvía cada vez")
    }

    func testMergeKeepsTheFieldsTheOtherLacks() {
        let base = DailyMetrics(date: day(0), weightKg: 80, source: .manual)
        let activity = DailyMetrics(date: day(0), steps: 9000, source: .health)
        let merged = base.merged(with: activity)
        XCTAssertEqual(merged.weightKg, 80)
        XCTAssertEqual(merged.steps, 9000)
    }

    // MARK: - Preferencias del coach

    /// Las claves del backend son neutras y los raw values de iOS son el texto que
    /// se pinta. Si alguien "simplifica" mandando el rawValue español, el backend
    /// lo rechaza con 422 y la preferencia deja de guardarse en silencio.
    func testCoachPreferencesUseTheBackendKeys() throws {
        var profile = UserProfile(
            name: "Fer", height: 178, weight: 79.6, age: 38,
            gender: .male, activityLevel: .moderate
        )
        profile.coachTone = .direct
        profile.coachDetail = .brief
        profile.coachAvoidWeightTalk = true

        let dto = UserProfileApiDTO.from(domain: profile)
        XCTAssertEqual(dto.coachTone, "direct")
        XCTAssertEqual(dto.coachDetail, "brief")
        XCTAssertEqual(dto.coachAvoidWeightTalk, true)

        let json = try JSONEncoder().encode(dto)
        let keys = try XCTUnwrap(
            JSONSerialization.jsonObject(with: json) as? [String: Any]
        ).keys
        XCTAssertTrue(keys.contains("coach_tone"), "snake_case, como el resto de la API")
        XCTAssertTrue(keys.contains("coach_avoid_weight_talk"))
    }

    func testCoachPreferencesSurviveTheRoundTrip() throws {
        let json = """
        {"name": "Fer", "height": 178, "weight": 79.6, "age": 38, "gender": "male",
         "activity_level": "moderate", "fitness_goal": null, "macro_profile": null,
         "free_days": [], "free_day_extra_calories": null,
         "coach_tone": "technical", "coach_detail": "detailed",
         "coach_avoid_weight_talk": true}
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(UserProfileApiDTO.self, from: json)
        let profile = try XCTUnwrap(dto.toDomain())
        XCTAssertEqual(profile.coachTone, .technical)
        XCTAssertEqual(profile.coachDetail, .detailed)
        XCTAssertEqual(profile.coachAvoidWeightTalk, true)
    }

    func testAProfileWithoutPreferencesIsStillValid() throws {
        // Perfiles creados antes de que existieran las preferencias.
        let json = """
        {"name": "Fer", "height": 178, "weight": 79.6, "age": 38, "gender": "male",
         "activity_level": "moderate", "free_days": []}
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(UserProfileApiDTO.self, from: json)
        let profile = try XCTUnwrap(dto.toDomain())
        XCTAssertNil(profile.coachTone, "sin preferencia, el coach habla como siempre")
        XCTAssertNil(profile.coachAvoidWeightTalk)
    }

    func testUnknownPreferenceFromTheServerDoesNotBreakDecoding() throws {
        let json = """
        {"name": "Fer", "height": 178, "weight": 79.6, "age": 38, "gender": "male",
         "activity_level": "moderate", "free_days": [], "coach_tone": "sarcastico"}
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(UserProfileApiDTO.self, from: json)
        let profile = try XCTUnwrap(dto.toDomain())
        XCTAssertNil(profile.coachTone, "un tono que iOS no conoce se ignora, no revienta el perfil")
    }
}
