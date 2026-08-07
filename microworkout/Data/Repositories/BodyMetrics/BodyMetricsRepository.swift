import Foundation

/// Peso por fecha, juntando las tres copias que puede haber.
///
/// Apple Salud es la FUENTE: ahí escribe la báscula y ahí escribimos nosotros lo
/// que el usuario anota, para no acabar con dos historiales que se contradicen.
/// Pero Salud puede no estar (permiso denegado, dispositivo sin HealthKit) y no
/// viaja entre móviles, así que:
///
/// - el dispositivo guarda su copia, que es lo que queda si no hay permiso;
/// - la cuenta guarda la serie, que es lo que sobrevive al cambiar de móvil y lo
///   único que el coach puede leer.
///
/// Al leer gana Salud, luego la cuenta y por último el dispositivo. Ninguna de las
/// tres esconde a las otras: si una falla, se sigue con las demás.
final class BodyMetricsRepository: BodyMetricsRepositoryProtocol {
    /// Cuánto histórico se mira al sincronizar. Dos años cubre a cualquiera que
    /// lleve tiempo pesándose sin convertir la primera sincronización en una
    /// descarga interminable.
    static let syncWindowDays = 730

    private let health: HealthRepositoryProtocol
    private let local: BodyMetricsLocalDataSourceProtocol
    private let remote: BodyMetricsRemoteDataSourceProtocol

    init(
        health: HealthRepositoryProtocol,
        local: BodyMetricsLocalDataSourceProtocol,
        remote: BodyMetricsRemoteDataSourceProtocol
    ) {
        self.health = health
        self.local = local
        self.remote = remote
    }

    private func isAuthenticated() async -> Bool {
        await MainActor.run { AuthSession.shared.state.isAuthenticated }
    }

    // MARK: - Lectura

    func getMeasurements(from start: Date, to end: Date) async throws -> [BodyMeasurement] {
        var byDay: [Date: BodyMeasurement] = [:]

        // De menos a más prioritario: cada fuente pisa a la anterior.
        for measurement in localMeasurements(from: start, to: end) {
            byDay[measurement.date] = measurement
        }
        if await isAuthenticated() {
            for dto in (try? await remote.list(from: start, to: end)) ?? [] {
                let measurement = dto.toDomain()
                byDay[measurement.date] = measurement
            }
        }
        for measurement in await healthMeasurements(from: start, to: end) {
            byDay[measurement.date] = measurement
        }

        return byDay.values.sorted { $0.date < $1.date }
    }

    private func localMeasurements(from start: Date, to end: Date) -> [BodyMeasurement] {
        local.getAll()
            .map { $0.toDomain() }
            .filter { $0.date >= Calendar.current.startOfDay(for: start) && $0.date <= end }
    }

    /// Medidas de Salud. Sin permiso o sin HealthKit devuelve vacío en vez de
    /// fallar: no tener Salud no es un error, es una app que funciona igual.
    private func healthMeasurements(from start: Date, to end: Date) async -> [BodyMeasurement] {
        guard health.isHealthDataAvailable else { return [] }
        let byDay = (try? await health.fetchBodyMass(startDate: start, endDate: end)) ?? [:]
        return byDay.map { BodyMeasurement(date: $0.key, weightKg: $0.value, source: .health) }
    }

    // MARK: - Escritura

    func saveWeight(_ kilograms: Double, on date: Date) async throws {
        let measurement = BodyMeasurement(date: date, weightKg: kilograms, source: .manual)

        // Primero el dispositivo: es la escritura que no puede fallar, así que el
        // dato queda a salvo aunque Salud lo rechace y el servidor no esté.
        local.save(measurement.toDTO())

        // Salud es la fuente: lo que se anota aquí tiene que estar allí, o la
        // próxima lectura mostrará el valor de la báscula y parecerá que se ha
        // perdido lo que el usuario escribió.
        if health.isHealthDataAvailable {
            try? await health.saveBodyMass(kilograms: kilograms, on: date)
        }

        if await isAuthenticated() {
            // Si falla, `syncLocalToRemote` lo sube después: está en el dispositivo.
            _ = try? await remote.upsert(measurement)
        }
    }

    func delete(date: Date) async throws {
        // No se borra de Salud: son datos del usuario que pueden venir de otra app
        // o de la báscula, y esta app no es quién para borrarlos. Se quita de donde
        // sí manda: dispositivo y cuenta.
        local.delete(date: date)
        if await isAuthenticated() {
            try? await remote.delete(date: date)
        }
    }

    // MARK: - Sincronización

    func pendingSyncCount() async throws -> Int {
        let (mine, synced) = try await syncSnapshot()
        return mine.filter { synced[$0.date] == nil }.count
    }

    func syncLocalToRemote() async throws -> Int {
        let (mine, synced) = try await syncSnapshot()
        let missing = mine.filter { synced[$0.date] == nil }
        guard !missing.isEmpty else { return 0 }
        // De golpe y no una por una: la primera sincronización puede traer años de
        // pesadas, y una petición por día sería absurda y frágil.
        return try await remote.upsertMany(missing)
    }

    /// Lo que hay en este dispositivo (Salud + copia local) y lo que ya está en la
    /// cuenta, para poder compararlos por día.
    private func syncSnapshot() async throws -> ([BodyMeasurement], [Date: BodyMeasurement]) {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -Self.syncWindowDays, to: end) ?? end

        var byDay: [Date: BodyMeasurement] = [:]
        for measurement in localMeasurements(from: start, to: end) {
            byDay[measurement.date] = measurement
        }
        for measurement in await healthMeasurements(from: start, to: end) {
            byDay[measurement.date] = measurement
        }

        // Esta sí se propaga: si no se sabe qué hay en la cuenta, no se puede decir
        // qué falta, y contestar "0 pendientes" sería mentir.
        let synced = try await remote.list(from: start, to: end)
        let syncedByDay = Dictionary(
            synced.map { ($0.toDomain().date, $0.toDomain()) },
            uniquingKeysWith: { _, last in last }
        )
        return (byDay.values.sorted { $0.date < $1.date }, syncedByDay)
    }
}
