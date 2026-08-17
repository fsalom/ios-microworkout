import Foundation

/// El plan semanal, con copia en el dispositivo y en la cuenta.
///
/// Modelo espejo, como el resto: el dispositivo siempre conserva su copia y la
/// cuenta es lo que sobrevive al cambiar de móvil (y lo único que el coach puede
/// leer, porque corre en el servidor).
///
/// Al leer manda la cuenta, con una excepción que importa: si la cuenta devuelve un
/// plan VACÍO y aquí hay uno, gana el local. Sin eso, iniciar sesión con un plan
/// hecho como invitado lo borraría de la pantalla antes de haberlo subido.
final class WeeklyPlanRepository: WeeklyPlanRepositoryProtocol {
    private let local: WeeklyPlanLocalDataSourceProtocol
    private let remote: WeeklyPlanRemoteDataSourceProtocol
    private let session: AuthStateProviding

    init(
        local: WeeklyPlanLocalDataSourceProtocol,
        remote: WeeklyPlanRemoteDataSourceProtocol,
        session: AuthStateProviding = SharedAuthState()
    ) {
        self.local = local
        self.remote = remote
        self.session = session
    }

    private func isAuthenticated() async -> Bool {
        await session.isAuthenticated
    }

    // MARK: - Lectura

    func getPlan() async throws -> WeeklyPlan {
        let localPlan = local.getPlan()?.toDomain() ?? .empty
        guard await isAuthenticated() else { return localPlan }

        // `try?`: sin red se sigue con lo que hay en el dispositivo. Propagar el
        // error dejaría la pantalla en blanco por estar en el metro.
        guard let remotePlan = (try? await remote.get())?.toDomain(), !remotePlan.isEmpty else {
            return localPlan
        }
        // Se refleja en el dispositivo lo que dice la cuenta: así el plan hecho en
        // otro móvil también está disponible sin conexión.
        local.savePlan(remotePlan.toDTO())
        return remotePlan
    }

    // MARK: - Escritura

    func savePlan(_ plan: WeeklyPlan) async throws {
        // Primero el dispositivo, que es la escritura que no puede fallar.
        local.savePlan(plan.toDTO())
        guard await isAuthenticated() else { return }
        // Si el servidor falla, `syncLocalToRemote` lo sube después: ya está guardado.
        _ = try? await remote.upsert(plan)
    }

    // MARK: - Sincronización

    func pendingSyncCount() async throws -> Int {
        let localPlan = local.getPlan()?.toDomain() ?? .empty
        guard !localPlan.isEmpty else { return 0 }
        // Este sí se propaga: si no se sabe qué hay en la cuenta, no se puede decir
        // que no falte nada.
        let remotePlan = try await remote.get().toDomain()
        return Self.matches(localPlan, remotePlan) ? 0 : 1
    }

    func syncLocalToRemote() async throws -> Int {
        let localPlan = local.getPlan()?.toDomain() ?? .empty
        guard !localPlan.isEmpty else { return 0 }
        let remotePlan = try await remote.get().toDomain()
        guard !Self.matches(localPlan, remotePlan) else { return 0 }
        _ = try await remote.upsert(localPlan)
        return 1
    }

    /// Si los dos planes dicen lo mismo.
    ///
    /// No vale `==`: el servidor normaliza (recorta el nombre, guarda `note` vacía
    /// como cadena vacía y la devuelve como `nil`), así que comparar los structs
    /// tal cual daría siempre "hay algo pendiente" y el plan se subiría en cada
    /// sincronización.
    private static func matches(_ mine: WeeklyPlan, _ synced: WeeklyPlan) -> Bool {
        guard mine.name.trimmed == synced.name.trimmed else { return false }
        let mineDays = normalized(mine.days)
        let syncedDays = normalized(synced.days)
        guard mineDays.count == syncedDays.count else { return false }
        return zip(mineDays, syncedDays).allSatisfy { $0 == $1 }
    }

    private static func normalized(_ days: [PlannedDay]) -> [PlannedDay] {
        days.map {
            PlannedDay(
                weekday: $0.weekday,
                sessionId: $0.sessionId,
                note: $0.note?.trimmed.isEmpty == false ? $0.note?.trimmed : nil
            )
        }
        .sorted { $0.weekday < $1.weekday }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
