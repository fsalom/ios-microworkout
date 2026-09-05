import Foundation

protocol HealthWorkoutSyncRepositoryProtocol {
    func pendingSyncCount() async throws -> Int
    func syncLocalToRemote() async throws -> Int
    /// Subida en caliente: como `syncLocalToRemote` pero con acelerador (una vez
    /// cada pocos minutos) y sin errores hacia fuera. Para llamarla al cargar la
    /// pestaña de ejercicio, que es cuando aparecen entrenos nuevos del reloj.
    func uploadOpportunistically() async
}

/// Espeja en la cuenta los entrenos de Apple Salud (Watch incluido).
///
/// Salud es la FUENTE y no se toca; la cuenta guarda el resumen, que es lo único
/// que la web (o cualquier cliente sin HealthKit) puede enseñar. Sin esto, un
/// entreno hecho con el reloj no existía fuera del móvil.
final class HealthWorkoutSyncRepository: HealthWorkoutSyncRepositoryProtocol {
    /// Ventana que se espeja. La misma que el resto de series largas: suficiente
    /// para el histórico útil sin convertir la primera sync en una descarga eterna.
    static let syncWindowDays = 90
    /// Mínimo entre subidas oportunistas: la pestaña se recarga a cada rato.
    static let opportunisticCooldown: TimeInterval = 10 * 60

    private var lastOpportunistic: Date?
    private let health: HealthUseCaseProtocol
    private let remote: HealthWorkoutRemoteDataSourceProtocol
    private let session: AuthStateProviding

    init(
        health: HealthUseCaseProtocol,
        remote: HealthWorkoutRemoteDataSourceProtocol,
        session: AuthStateProviding = SharedAuthState()
    ) {
        self.health = health
        self.remote = remote
        self.session = session
    }

    func pendingSyncCount() async throws -> Int {
        try await missing().count
    }

    func syncLocalToRemote() async throws -> Int {
        let pending = try await missing()
        guard !pending.isEmpty else { return 0 }
        return try await remote.upsertMany(pending)
    }

    func uploadOpportunistically() async {
        if let last = lastOpportunistic,
           Date().timeIntervalSince(last) < Self.opportunisticCooldown {
            return
        }
        lastOpportunistic = Date()
        // `try?`: es mantenimiento de fondo; la sync de login/manual reintentará.
        _ = try? await syncLocalToRemote()
    }

    /// Entrenos de Salud que la cuenta aún no tiene.
    private func missing() async throws -> [HealthWorkout] {
        guard await session.isAuthenticated else { return [] }
        // Sin permiso de Salud no hay nada que espejar — no es un error.
        let workouts = (try? await health.getRecentWorkouts()) ?? []
        guard !workouts.isEmpty else { return [] }

        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -Self.syncWindowDays, to: end) ?? end
        let windowed = workouts.filter { $0.startDate >= start }
        guard !windowed.isEmpty else { return [] }

        // Este sí se propaga: sin saber qué hay en la cuenta no se puede decir
        // qué falta, y contestar "0 pendientes" sería mentir.
        let synced = try await remote.syncedIds(from: start, to: end)
        return windowed.filter { !synced.contains($0.id) }
    }
}
