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

    private let session: AuthStateProviding

    init(
        health: HealthRepositoryProtocol,
        local: BodyMetricsLocalDataSourceProtocol,
        remote: BodyMetricsRemoteDataSourceProtocol,
        session: AuthStateProviding = SharedAuthState()
    ) {
        self.health = health
        self.local = local
        self.remote = remote
        self.session = session
    }

    private func isAuthenticated() async -> Bool {
        await session.isAuthenticated
    }

    // MARK: - Lectura

    func getMeasurements(from start: Date, to end: Date) async throws -> [DailyMetrics] {
        var byDay: [Date: DailyMetrics] = [:]

        // De menos a más prioritario, CAMPO A CAMPO. Reemplazar el registro entero
        // sería perder datos: el día que la cuenta tiene el peso (que vino de otro
        // móvil) y Salud tiene los pasos, quedarse con uno de los dos borra el otro.
        func absorb(_ measurements: [DailyMetrics]) {
            for measurement in measurements {
                byDay[measurement.date] = byDay[measurement.date]?.merged(with: measurement)
                    ?? measurement
            }
        }

        absorb(localMeasurements(from: start, to: end))
        if await isAuthenticated() {
            absorb(((try? await remote.list(from: start, to: end)) ?? []).map { $0.toDomain() })
        }
        absorb(await healthMeasurements(from: start, to: end))

        // Los días que el usuario borró se filtran AL FINAL, después de juntar las
        // tres fuentes. Quitarlos solo del dispositivo no servía de nada: Salud
        // conserva la muestra y la volvía a traer, así que borrar un peso duraba
        // hasta la siguiente lectura de la pantalla.
        let deleted = local.deletedDates()
        return byDay.values
            .filter { !deleted.contains($0.date) }
            .sorted { $0.date < $1.date }
    }

    private func localMeasurements(from start: Date, to end: Date) -> [DailyMetrics] {
        local.getAll()
            .map { $0.toDomain() }
            .filter { $0.date >= Calendar.current.startOfDay(for: start) && $0.date <= end }
    }

    /// El registro diario según Apple Salud: peso, actividad y recuperación.
    ///
    /// Cada serie se pide por separado y se fusiona por día. Cada una va con su
    /// `try?`: que el usuario no haya dado permiso a la frecuencia cardiaca no
    /// puede dejarnos sin los pasos. Sin permiso o sin HealthKit se devuelve vacío
    /// en vez de fallar — no tener Salud no es un error, es una app que funciona
    /// igual.
    private func healthMeasurements(from start: Date, to end: Date) async -> [DailyMetrics] {
        guard health.isHealthDataAvailable else { return [] }

        async let weights = try? await health.fetchBodyMass(startDate: start, endDate: end)
        async let steps = try? await health.fetchStepsCount(startDate: start, endDate: end)
        async let energy = try? await health.fetchActiveEnergy(startDate: start, endDate: end)
        async let exercise = try? await health.fetchExerciseTime(startDate: start, endDate: end)
        async let standing = try? await health.fetchStandingTime(startDate: start, endDate: end)
        async let restingHR = try? await health.fetchRestingHeartRate(startDate: start, endDate: end)

        var byDay: [Date: DailyMetrics] = [:]

        func merge(_ day: Date, _ apply: (inout DailyMetrics) -> Void) {
            let normalized = Calendar.current.startOfDay(for: day)
            var entry = byDay[normalized] ?? DailyMetrics(date: normalized, source: .health)
            apply(&entry)
            byDay[normalized] = entry
        }

        // Los `fetch...` de pasos, ejercicio y de pie ya devolvían opcional, y el
        // `try?` añade otro nivel: se aplanan aquí para que el bucle quede legible.
        let weightByDay = await weights ?? [:]
        let stepByDay = (await steps ?? nil) ?? [:]
        let energyByDay = await energy ?? [:]
        let exerciseByDay = (await exercise ?? nil) ?? [:]
        let standingByDay = (await standing ?? nil) ?? [:]
        let restingByDay = await restingHR ?? [:]

        for (day, value) in weightByDay { merge(day) { $0.weightKg = value } }
        for (day, value) in stepByDay { merge(day) { $0.steps = Int(value) } }
        for (day, value) in energyByDay { merge(day) { $0.activeKcal = value } }
        for (day, value) in exerciseByDay { merge(day) { $0.exerciseMinutes = value } }
        for (day, value) in standingByDay { merge(day) { $0.standingMinutes = value } }
        for (day, value) in restingByDay { merge(day) { $0.restingHeartRate = value } }

        return Array(byDay.values)
    }

    // MARK: - Escritura

    func saveWeight(_ kilograms: Double, on date: Date) async throws {
        let measurement = DailyMetrics(date: date, weightKg: kilograms, source: .manual)

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
        let snapshot = try await syncSnapshot()
        return snapshot.missing.count + snapshot.staleDeletions.count
    }

    func syncLocalToRemote() async throws -> Int {
        let snapshot = try await syncSnapshot()
        var count = 0

        // Primero los borrados que no llegaron a la cuenta (sin red al borrar). Si
        // no se reintentan, el día sigue en el servidor y reaparece en cuanto
        // entras desde otro móvil: la lápida solo vive en el dispositivo que borró.
        for date in snapshot.staleDeletions {
            try await remote.delete(date: date)
            count += 1
        }

        guard !snapshot.missing.isEmpty else { return count }
        // De golpe y no una por una: la primera sincronización puede traer años de
        // días registrados, y una petición por día sería absurda y frágil.
        return count + (try await remote.upsertMany(snapshot.missing))
    }

    /// `true` si este dispositivo tiene algo que la cuenta no.
    ///
    /// No basta con "el día no está en la cuenta": ahora un día lleva varias
    /// métricas, y el caso normal es que la cuenta ya tenga el peso de ayer y le
    /// falten los pasos. Comparando solo por fecha, esos pasos no se subirían nunca.
    private static func needsUpload(_ mine: DailyMetrics, comparedTo synced: DailyMetrics?) -> Bool {
        guard !mine.isEmpty else { return false }
        guard let synced else { return true }
        var candidate = synced.merged(with: mine)
        // La fuente no cuenta: que un dato venga de Salud o de la app no es motivo
        // para reenviarlo en cada sincronización.
        candidate.source = synced.source
        return candidate != synced
    }

    /// Lo que falta por subir y lo que falta por borrar, ya resuelto contra lo que
    /// la cuenta tiene hoy.
    private struct SyncSnapshot {
        /// Días de este dispositivo que la cuenta no tiene (o tiene incompletos).
        let missing: [DailyMetrics]
        /// Días borrados aquí que la cuenta todavía tiene.
        let staleDeletions: [Date]
    }

    /// Compara lo que hay en este dispositivo (Salud + copia local, menos lo que el
    /// usuario borró) con lo que ya está en la cuenta.
    private func syncSnapshot() async throws -> SyncSnapshot {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -Self.syncWindowDays, to: end) ?? end
        let deleted = local.deletedDates()

        var byDay: [Date: DailyMetrics] = [:]
        // Un día borrado no es un día pendiente de subir. Sin este filtro, Salud lo
        // devolvía en cada sincronización y se volvía a subir eternamente: borrarlo
        // en la cuenta no servía de nada.
        for measurement in localMeasurements(from: start, to: end) where !deleted.contains(measurement.date) {
            byDay[measurement.date] = byDay[measurement.date]?.merged(with: measurement) ?? measurement
        }
        for measurement in await healthMeasurements(from: start, to: end) where !deleted.contains(measurement.date) {
            byDay[measurement.date] = byDay[measurement.date]?.merged(with: measurement) ?? measurement
        }

        // Esta sí se propaga: si no se sabe qué hay en la cuenta, no se puede decir
        // qué falta, y contestar "0 pendientes" sería mentir.
        let synced = try await remote.list(from: start, to: end).map { $0.toDomain() }
        let syncedByDay = Dictionary(
            synced.map { ($0.date, $0) },
            uniquingKeysWith: { _, last in last }
        )

        return SyncSnapshot(
            missing: byDay.values
                .filter { Self.needsUpload($0, comparedTo: syncedByDay[$0.date]) }
                .sorted { $0.date < $1.date },
            staleDeletions: deleted.filter { syncedByDay[$0] != nil }.sorted()
        )
    }
}
