import XCTest
@testable import microworkout

/// El espejo de las entradas manuales: la última categoría que era solo-dispositivo.
final class WorkoutEntrySyncTests: XCTestCase {

    private enum Fake: Error { case offline }

    private final class FakeLocal: WorkoutEntryDataSourceProtocol {
        var entries: [WorkoutEntryDTO] = []
        func getAll() async throws -> [WorkoutEntryDTO] { entries }
        func getAll(for exerciseID: UUID) async throws -> [WorkoutEntryDTO] {
            entries.filter { $0.exercise.id == exerciseID }
        }
        func add(_ entry: WorkoutEntryDTO) async throws {
            entries.append(entry)
        }
        func update(_ entry: WorkoutEntryDTO) async throws {
            entries.removeAll { $0.id == entry.id }
            entries.append(entry)
        }
        func delete(entryID: UUID) async throws {
            entries.removeAll { $0.id == entryID }
        }
    }

    private final class SpyRemote: WorkoutEntryRemoteDataSourceProtocol {
        var synced: Set<UUID> = []
        var isOffline = false
        private(set) var upserted: [UUID] = []
        private(set) var deleted: [UUID] = []

        func syncedIds() async throws -> Set<UUID> {
            if isOffline { throw Fake.offline }
            return synced
        }
        func upsertMany(_ entries: [WorkoutEntry]) async throws -> Int {
            if isOffline { throw Fake.offline }
            upserted.append(contentsOf: entries.map(\.id))
            synced.formUnion(entries.map(\.id))
            return entries.count
        }
        func delete(entryID: UUID) async throws {
            if isOffline { throw Fake.offline }
            deleted.append(entryID)
        }
    }

    private struct StubSession: AuthStateProviding {
        let authenticated: Bool
        var isAuthenticated: Bool { get async { authenticated } }
    }

    private func entry(_ id: UUID = UUID()) -> WorkoutEntry {
        WorkoutEntry(
            id: id,
            exercise: Exercise(name: "Dominadas", type: .reps),
            date: Date(),
            reps: 10,
            isCompleted: true
        )
    }

    func testAddSavesLocallyAndMirrorsToTheAccount() async throws {
        let local = FakeLocal()
        let remote = SpyRemote()
        let repository = WorkoutEntryRepository(
            dataSource: local, remote: remote, session: StubSession(authenticated: true)
        )

        let new = entry()
        try await repository.add(new)

        XCTAssertEqual(local.entries.count, 1)
        XCTAssertEqual(remote.upserted, [new.id])
    }

    /// Sin red al guardar, el dato queda en el dispositivo y la sincronización lo
    /// recoge después: el guardado nunca puede fallar por estar en el metro.
    func testOfflineAddSurvivesAndSyncsLater() async throws {
        let local = FakeLocal()
        let remote = SpyRemote()
        remote.isOffline = true
        let repository = WorkoutEntryRepository(
            dataSource: local, remote: remote, session: StubSession(authenticated: true)
        )

        try await repository.add(entry())
        XCTAssertEqual(local.entries.count, 1)
        XCTAssertTrue(remote.upserted.isEmpty)

        remote.isOffline = false
        let pending = try await repository.pendingSyncCount()
        XCTAssertEqual(pending, 1)
        let uploaded = try await repository.syncLocalToRemote()
        XCTAssertEqual(uploaded, 1)
        let after = try await repository.pendingSyncCount()
        XCTAssertEqual(after, 0)
    }

    func testGuestStaysLocalAndCountsNothingPending() async throws {
        let local = FakeLocal()
        let remote = SpyRemote()
        remote.isOffline = true   // si tocara la red, fallaría
        let repository = WorkoutEntryRepository(
            dataSource: local, remote: remote, session: StubSession(authenticated: false)
        )

        try await repository.add(entry())
        XCTAssertEqual(local.entries.count, 1)
        let pending = try await repository.pendingSyncCount()
        XCTAssertEqual(pending, 0)
    }

    func testDeletePropagatesToTheAccount() async throws {
        let local = FakeLocal()
        let remote = SpyRemote()
        let repository = WorkoutEntryRepository(
            dataSource: local, remote: remote, session: StubSession(authenticated: true)
        )
        let target = entry()
        try await repository.add(target)

        try await repository.delete(entryID: target.id)

        XCTAssertTrue(local.entries.isEmpty)
        XCTAssertEqual(remote.deleted, [target.id])
    }
}
