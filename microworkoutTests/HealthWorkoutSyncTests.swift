import XCTest
@testable import microworkout

/// El espejo de los entrenos de Apple Salud en la cuenta.
///
/// Lo que se vigila: que solo se suba lo que falta (la primera sync puede repetir
/// semanas y el backend deduplica, pero reenviar todo en cada pasada es absurdo),
/// que el invitado no cuente pendientes, y que el acelerador de la subida en
/// caliente no deje pasar dos seguidas.
final class HealthWorkoutSyncTests: XCTestCase {

    private enum Fake: Error { case offline }

    private final class StubHealth: HealthUseCaseProtocol {
        var workouts: [HealthWorkout] = []
        var isHealthDataAvailable: Bool { true }
        var authorizationStatus: HealthAuthorizationStatus { .authorized }
        func requestAuthorization() async throws -> Bool { true }
        func getDaysPerWeeksWithHealthInfo(for numberOfWeeks: Int) async throws -> [[HealthDay]] { [] }
        func getHealthInfoForToday() async throws -> HealthDay { HealthDay(date: Date()) }
        func getPreviousWeekAverageSteps() async throws -> Int { 0 }
        func getRecentWorkouts() async throws -> [HealthWorkout] { workouts }
        func linkWorkout(_ workoutID: String, to trainingID: UUID) {}
        func unlinkWorkout(_ workoutID: String) {}
        func linkWorkout(_ workoutID: String, toEntryDate entryDate: String) {}
        func unlinkEntryFromWorkout(_ workoutID: String) {}
    }

    private final class SpyRemote: HealthWorkoutRemoteDataSourceProtocol {
        var synced: Set<String> = []
        var isOffline = false
        private(set) var uploaded: [[HealthWorkout]] = []

        func syncedIds(from start: Date, to end: Date) async throws -> Set<String> {
            if isOffline { throw Fake.offline }
            return synced
        }

        func upsertMany(_ workouts: [HealthWorkout]) async throws -> Int {
            if isOffline { throw Fake.offline }
            uploaded.append(workouts)
            synced.formUnion(workouts.map(\.id))
            return workouts.count
        }
    }

    private struct StubSession: AuthStateProviding {
        let authenticated: Bool
        var isAuthenticated: Bool { get async { authenticated } }
    }

    private func workout(_ id: String, daysAgo: Int = 1) -> HealthWorkout {
        HealthWorkout(
            id: id, activityTypeName: "Fuerza",
            startDate: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            endDate: Date(), durationInSeconds: 3600,
            totalCalories: 400, totalDistance: nil, averageHeartRate: 110,
            linkedTrainingID: nil, linkedEntryDate: nil
        )
    }

    func testOnlyMissingWorkoutsAreUploaded() async throws {
        let health = StubHealth()
        let remote = SpyRemote()
        health.workouts = [workout("a"), workout("b"), workout("c")]
        remote.synced = ["a", "b"]

        let repository = HealthWorkoutSyncRepository(
            health: health, remote: remote, session: StubSession(authenticated: true)
        )

        let pendingBefore = try await repository.pendingSyncCount()
        XCTAssertEqual(pendingBefore, 1)
        let uploaded = try await repository.syncLocalToRemote()
        XCTAssertEqual(uploaded, 1)
        XCTAssertEqual(remote.uploaded.flatMap { $0 }.map(\.id), ["c"])
        let pendingAfter = try await repository.pendingSyncCount()
        XCTAssertEqual(pendingAfter, 0)
    }

    /// Un entreno de hace medio año queda fuera de la ventana: no se sube ni
    /// cuenta como pendiente eternamente.
    func testOldWorkoutsAreOutsideTheWindow() async throws {
        let health = StubHealth()
        health.workouts = [workout("viejo", daysAgo: 200)]
        let repository = HealthWorkoutSyncRepository(
            health: health, remote: SpyRemote(), session: StubSession(authenticated: true)
        )
        let pending = try await repository.pendingSyncCount()
        XCTAssertEqual(pending, 0)
    }

    func testGuestHasNothingPending() async throws {
        let health = StubHealth()
        health.workouts = [workout("a")]
        let remote = SpyRemote()
        remote.isOffline = true   // si consultara la cuenta, fallaría
        let repository = HealthWorkoutSyncRepository(
            health: health, remote: remote, session: StubSession(authenticated: false)
        )
        let pending = try await repository.pendingSyncCount()
        XCTAssertEqual(pending, 0)
    }

    /// La subida en caliente respeta el enfriamiento: la pestaña se recarga a
    /// cada rato y cada pasada extra es un GET al servidor.
    func testOpportunisticUploadIsThrottled() async {
        let health = StubHealth()
        let remote = SpyRemote()
        health.workouts = [workout("a")]
        let repository = HealthWorkoutSyncRepository(
            health: health, remote: remote, session: StubSession(authenticated: true)
        )

        await repository.uploadOpportunistically()
        health.workouts.append(workout("b"))
        await repository.uploadOpportunistically()   // dentro del enfriamiento: no va

        XCTAssertEqual(remote.uploaded.count, 1)
        XCTAssertEqual(remote.uploaded.first?.map(\.id), ["a"])
    }
}
