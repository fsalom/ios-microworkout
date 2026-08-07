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
        func fetchStepsCount(startDate: Date, endDate: Date) async throws -> [Date: Double]? { nil }
        func fetchStandingTime() async throws -> Double? { nil }
        func fetchStandingTime(startDate: Date, endDate: Date) async throws -> [Date: Double]? { nil }
        func fetchWorkouts() async throws -> [HealthWorkout] { [] }

        func fetchBodyMass(startDate: Date, endDate: Date) async throws -> [Date: Double] {
            if failsOnRead { throw Fake.denied }
            return byDay
        }

        func saveBodyMass(kilograms: Double, on date: Date) async throws {
            if failsOnWrite { throw Fake.denied }
            saved.append((kilograms, date))
        }
    }

    private final class FakeLocal: BodyMetricsLocalDataSourceProtocol {
        var stored: [BodyMeasurementDTO] = []
        func getAll() -> [BodyMeasurementDTO] { stored }
        func save(_ measurement: BodyMeasurementDTO) {
            stored.removeAll { Calendar.current.isDate($0.date, inSameDayAs: measurement.date) }
            stored.append(measurement)
        }
        func delete(date: Date) {
            stored.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        }
    }

    private final class FakeRemote: BodyMetricsRemoteDataSourceProtocol {
        var stored: [BodyMeasurement] = []
        var isOffline = false
        private(set) var bulkCalls = 0
        private(set) var upsertCalls = 0

        func list(from start: Date?, to end: Date?) async throws -> [BodyMeasurementApiDTO] {
            if isOffline { throw Fake.offline }
            // El doble devuelve entidades ya mapeadas: lo que se prueba aquí es la
            // fusión, no el JSON (eso lo cubre `testDateContract`).
            return try stored.map { try Self.dto(from: $0) }
        }

        func upsert(_ measurement: BodyMeasurement) async throws -> BodyMeasurementApiDTO {
            if isOffline { throw Fake.offline }
            upsertCalls += 1
            stored.removeAll { $0.date == measurement.date }
            stored.append(measurement)
            return try Self.dto(from: measurement)
        }

        func upsertMany(_ measurements: [BodyMeasurement]) async throws -> Int {
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
        static func dto(from measurement: BodyMeasurement) throws -> BodyMeasurementApiDTO {
            var json: [String: Any] = [
                "date": BodyMetricsDateFormat.day.string(from: measurement.date),
                "source": measurement.source.rawValue,
            ]
            if let weight = measurement.weightKg { json["weight_kg"] = weight }
            let data = try JSONSerialization.data(withJSONObject: json)
            return try JSONDecoder().decode(BodyMeasurementApiDTO.self, from: data)
        }
    }

    // MARK: - Utilidades

    private func day(_ offset: Int) -> Date {
        Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        )
    }

    @MainActor
    private func withAuthenticatedSession(_ body: () async throws -> Void) async rethrows {
        let previous = AuthSession.shared.state
        AuthSession.shared.setAuthenticated(
            AuthenticatedUser(id: 1, email: "a@b.c", fullname: "Test", phone: nil)
        )
        defer {
            if case .authenticated(let user) = previous {
                AuthSession.shared.setAuthenticated(user)
            } else {
                AuthSession.shared.setGuest()
            }
        }
        try await body()
    }

    private func makeRepository(
        health: FakeHealth = FakeHealth(),
        local: FakeLocal = FakeLocal(),
        remote: FakeRemote = FakeRemote()
    ) -> BodyMetricsRepository {
        BodyMetricsRepository(health: health, local: local, remote: remote)
    }

    // MARK: - Quién gana

    func testHealthWinsOverTheAccountForTheSameDay() async throws {
        let health = FakeHealth()
        health.byDay = [day(0): 79.5]
        let remote = FakeRemote()
        remote.stored = [BodyMeasurement(date: day(0), weightKg: 80.0, source: .manual)]
        let repository = makeRepository(health: health, remote: remote)

        try await withAuthenticatedSession {
            let result = try await repository.getMeasurements(from: day(-7), to: day(0))
            XCTAssertEqual(result.count, 1, "un día, una medida")
            XCTAssertEqual(result.first?.weightKg, 79.5, "Salud es la fuente: manda su valor")
        }
    }

    func testDeniedHealthDoesNotHideTheOtherSources() async throws {
        let health = FakeHealth()
        health.failsOnRead = true
        let local = FakeLocal()
        local.stored = [BodyMeasurement(date: day(-1), weightKg: 81.0).toDTO()]
        let repository = makeRepository(health: health, local: local)

        let result = try await repository.getMeasurements(from: day(-7), to: day(0))
        XCTAssertEqual(result.first?.weightKg, 81.0, "sin permiso de Salud se sigue viendo lo del dispositivo")
    }

    func testServerFailureDoesNotHideLocalWeights() async throws {
        let local = FakeLocal()
        local.stored = [BodyMeasurement(date: day(-2), weightKg: 77.0).toDTO()]
        let remote = FakeRemote()
        remote.isOffline = true
        let repository = makeRepository(local: local, remote: remote)

        try await withAuthenticatedSession {
            let result = try await repository.getMeasurements(from: day(-7), to: day(0))
            XCTAssertEqual(result.count, 1, "una caída del servidor no puede vaciar la gráfica")
        }
    }

    // MARK: - Anotar

    func testSavingWritesToHealthAndTheAccount() async throws {
        let health = FakeHealth()
        let local = FakeLocal()
        let remote = FakeRemote()
        let repository = makeRepository(health: health, local: local, remote: remote)

        try await withAuthenticatedSession {
            try await repository.saveWeight(78.4, on: day(0))
            XCTAssertEqual(health.saved.first?.kg, 78.4, "lo anotado tiene que acabar en Salud")
            XCTAssertEqual(local.stored.count, 1, "y en el dispositivo")
            XCTAssertEqual(remote.upsertCalls, 1, "y en la cuenta")
        }
    }

    func testWeightSurvivesWhenHealthAndServerBothFail() async throws {
        let health = FakeHealth()
        health.failsOnWrite = true
        let local = FakeLocal()
        let remote = FakeRemote()
        remote.isOffline = true
        let repository = makeRepository(health: health, local: local, remote: remote)

        try await withAuthenticatedSession {
            try await repository.saveWeight(78.4, on: day(0))
            XCTAssertEqual(local.stored.first?.weightKg, 78.4, "el dato no se pierde por que fallen los otros dos")
        }
    }

    func testDeletingDoesNotTouchAppleHealth() async throws {
        let health = FakeHealth()
        health.byDay = [day(0): 79.5]
        let local = FakeLocal()
        local.stored = [BodyMeasurement(date: day(0), weightKg: 79.5).toDTO()]
        let repository = makeRepository(health: health, local: local)

        try await repository.delete(date: day(0))
        XCTAssertTrue(local.stored.isEmpty, "se borra del dispositivo")
        XCTAssertEqual(health.byDay.count, 1, "pero NO de Salud: esos datos son del usuario")
    }

    func testGuestModeNeverCallsTheServer() async throws {
        await MainActor.run { AuthSession.shared.setGuest() }
        let health = FakeHealth()
        let local = FakeLocal()
        let remote = FakeRemote()
        remote.isOffline = true   // cualquier llamada haría fallar el test
        let repository = makeRepository(health: health, local: local, remote: remote)

        try await repository.saveWeight(78.4, on: day(0))
        XCTAssertEqual(local.stored.count, 1)
        XCTAssertEqual(remote.upsertCalls, 0)
    }

    // MARK: - Sincronización

    func testSyncUploadsWhatTheAccountIsMissing() async throws {
        let health = FakeHealth()
        health.byDay = [day(-1): 80.0, day(-2): 80.5]
        let local = FakeLocal()
        local.stored = [BodyMeasurement(date: day(-3), weightKg: 81.0).toDTO()]
        let remote = FakeRemote()
        remote.stored = [BodyMeasurement(date: day(-1), weightKg: 80.0, source: .health)]
        let repository = makeRepository(health: health, local: local, remote: remote)

        try await withAuthenticatedSession {
            let pending = try await repository.pendingSyncCount()
            XCTAssertEqual(pending, 2, "faltan los dos días que no están en la cuenta")
            let uploaded = try await repository.syncLocalToRemote()
            XCTAssertEqual(uploaded, 2)
            XCTAssertEqual(remote.bulkCalls, 1, "en una sola petición, no una por día")
            let remaining = try await repository.pendingSyncCount()
            XCTAssertEqual(remaining, 0)
        }
    }

    // MARK: - Tendencia

    func testTrendNeedsTwoMeasurements() {
        XCTAssertNil(
            WeightTrend.from([BodyMeasurement(date: day(0), weightKg: 80)]),
            "una sola medida no es una tendencia"
        )
    }

    func testTrendComputesDeltaAndWeeklyRate() throws {
        let trend = try XCTUnwrap(WeightTrend.from([
            BodyMeasurement(date: day(-28), weightKg: 82.0),
            BodyMeasurement(date: day(-14), weightKg: 81.0),
            BodyMeasurement(date: day(0), weightKg: 79.5),
        ]))
        XCTAssertEqual(trend.deltaKg, -2.5)
        XCTAssertEqual(trend.days, 28)
        XCTAssertEqual(trend.kgPerWeek, -0.63)
    }

    func testWeeklyRateIsNilBelowAWeek() throws {
        let trend = try XCTUnwrap(WeightTrend.from([
            BodyMeasurement(date: day(-2), weightKg: 80.0),
            BodyMeasurement(date: day(0), weightKg: 79.6),
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

        let dto = try JSONDecoder().decode(BodyMeasurementApiDTO.self, from: json)
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
        let dto = try JSONDecoder().decode(BodyMeasurementApiDTO.self, from: json)
        XCTAssertEqual(dto.toDomain().source, .manual, "una fuente desconocida no puede reventar el decodificado")
    }

    func testMeasurementNormalizesToStartOfDay() {
        let noon = Calendar.current.date(bySettingHour: 13, minute: 27, second: 0, of: Date())!
        let measurement = BodyMeasurement(date: noon, weightKg: 80)
        XCTAssertEqual(measurement.date, Calendar.current.startOfDay(for: noon),
                       "la identidad de una medida es el día, no el instante")
    }
}
