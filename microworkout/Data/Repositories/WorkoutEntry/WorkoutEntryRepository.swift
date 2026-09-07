import Foundation

/// Entradas manuales de ejercicio, en espejo con la cuenta.
///
/// El dispositivo manda (es donde se crean y editan); la cuenta guarda la copia
/// que ven la web y el coach del servidor. Las escrituras van primero a local
/// —la que no puede fallar— y a la cuenta con `try?`: sin red, la
/// sincronización las recoge después.
///
/// Un borrado sin red deja la copia del servidor huérfana hasta el siguiente
/// borrado con red; NO se poda desde la sincronización a propósito — comparar
/// "lo que el servidor tiene y yo no" y borrar destruiría los datos de otro
/// dispositivo (o los tuyos tras reinstalar).
class WorkoutEntryRepository: WorkoutEntryRepositoryProtocol {
    private let dataSource: WorkoutEntryDataSourceProtocol
    private let remote: WorkoutEntryRemoteDataSourceProtocol
    private let session: AuthStateProviding

    init(
        dataSource: WorkoutEntryDataSourceProtocol,
        remote: WorkoutEntryRemoteDataSourceProtocol,
        session: AuthStateProviding = SharedAuthState()
    ) {
        self.dataSource = dataSource
        self.remote = remote
        self.session = session
    }

    private func isAuthenticated() async -> Bool {
        await session.isAuthenticated
    }

    func getAll() async throws -> [WorkoutEntry] {
        try await dataSource.getAll().map { $0.toDomain() }
    }

    func getAll(for exerciseID: UUID) async throws -> [WorkoutEntry] {
        try await dataSource.getAll(for: exerciseID).map { $0.toDomain() }
    }

    func add(_ entry: WorkoutEntry) async throws {
        try await dataSource.add(entry.toDTO())
        guard await isAuthenticated() else { return }
        _ = try? await remote.upsertMany([entry])
    }

    func update(_ entry: WorkoutEntry) async throws {
        try await dataSource.update(entry.toDTO())
        guard await isAuthenticated() else { return }
        _ = try? await remote.upsertMany([entry])
    }

    func delete(entryID: UUID) async throws {
        try await dataSource.delete(entryID: entryID)
        guard await isAuthenticated() else { return }
        try? await remote.delete(entryID: entryID)
    }

    // MARK: - Sincronización

    func pendingSyncCount() async throws -> Int {
        guard await isAuthenticated() else { return 0 }
        return try await missing().count
    }

    func syncLocalToRemote() async throws -> Int {
        guard await isAuthenticated() else { return 0 }
        let pending = try await missing()
        guard !pending.isEmpty else { return 0 }
        return try await remote.upsertMany(pending)
    }

    private func missing() async throws -> [WorkoutEntry] {
        let local = try await getAll()
        guard !local.isEmpty else { return [] }
        // Este sí se propaga: sin saber qué hay en la cuenta, "0 pendientes" es mentira.
        let synced = try await remote.syncedIds()
        return local.filter { !synced.contains($0.id) }
    }
}
