import XCTest
@testable import microworkout

/// Este archivo no existía y no podía existir: `ProfileViewModel` leía
/// `AuthSession.shared` (un singleton global) y recibía use cases por su clase
/// concreta, que no hay forma de doblar. Con la sesión inyectada y el componente
/// exponiendo protocolos, la lógica de "esto requiere cuenta" ya se puede fijar.
///
/// Es justo la lógica que más silenciosamente se rompe: cuando falla, la pantalla
/// no da error — simplemente no hace nada.
final class ProfileViewModelTests: XCTestCase {

    // MARK: - Dobles

    private final class FakeRouter: ProfileRouterProtocol {
        var visited: [String] = []
        func goToChat() { visited.append("chat") }
        func goToWeightProgress() { visited.append("weight") }
        func goToUserReport() { visited.append("report") }
    }

    private final class FakeProfileUseCase: UserProfileUseCaseProtocol {
        var profile: UserProfile?
        var saveFails = false
        private(set) var saved: [UserProfile] = []

        func saveProfile(_ profile: UserProfile) async throws {
            if saveFails { throw DomainError.network(underlying: URLError(.notConnectedToInternet)) }
            saved.append(profile)
            self.profile = profile
        }
        func getProfile() async throws -> UserProfile? { profile }
        func setOnboardingCompleted(_ completed: Bool) {}
        func hasCompletedOnboarding() -> Bool { true }
    }

    private func makeProfile(
        tone: UserProfile.CoachTone? = nil,
        detail: UserProfile.CoachDetail? = nil,
        avoidWeightTalk: Bool? = nil
    ) -> UserProfile {
        UserProfile(
            name: "Fer", height: 178, weight: 79.6, age: 38,
            gender: .male, activityLevel: .moderate,
            coachTone: tone, coachDetail: detail, coachAvoidWeightTalk: avoidWeightTalk
        )
    }

    private struct StubHealthUseCase: HealthUseCaseProtocol {
        var isHealthDataAvailable: Bool { false }
        var authorizationStatus: HealthAuthorizationStatus { .notDetermined }
        func requestAuthorization() async throws -> Bool { false }
        func getDaysPerWeeksWithHealthInfo(for numberOfWeeks: Int) async throws -> [[HealthDay]] { [] }
        func getHealthInfoForToday() async throws -> HealthDay { HealthDay(date: Date()) }
        func getPreviousWeekAverageSteps() async throws -> Int { 0 }
        func getRecentWorkouts() async throws -> [HealthWorkout] { [] }
        func linkWorkout(_ workoutID: String, to trainingID: UUID) {}
        func unlinkWorkout(_ workoutID: String) {}
        func linkWorkout(_ workoutID: String, toEntryDate entryDate: String) {}
        func unlinkEntryFromWorkout(_ workoutID: String) {}
    }

    private struct StubAuthService: AuthServiceProtocol {
        func signInWithApple(authCode: String) async throws {}
        func signInWithGoogle() async throws {}
        func logout() async {}
        @discardableResult func handleOpenURL(_ url: URL) -> Bool { false }
    }

    /// Sesión que el test puede cambiar a media operación, que es lo que hace
    /// `SessionAwareNetwork` cuando el token muere.
    private final class MutableSession: AuthStateProviding, @unchecked Sendable {
        private let lock = NSLock()
        private var value: Bool

        init(_ value: Bool) { self.value = value }

        var isAuthenticated: Bool {
            get async {
                lock.lock(); defer { lock.unlock() }
                return value
            }
        }

        func set(_ newValue: Bool) {
            lock.lock(); value = newValue; lock.unlock()
        }
    }

    private final class FakeSyncUseCase: SyncLocalDataUseCaseProtocol, @unchecked Sendable {
        private let lock = NSLock()
        private var statusCallCount = 0
        private var syncCallCount = 0
        var uploaded = 2
        /// Se ejecuta al empezar `sync()`, para simular que la sesión caduca a medias.
        var onSync: (() -> Void)?

        var statusCalls: Int { lock.lock(); defer { lock.unlock() }; return statusCallCount }
        var syncCalls: Int { lock.lock(); defer { lock.unlock() }; return syncCallCount }

        func status() async -> SyncReport {
            lock.lock(); statusCallCount += 1; lock.unlock()
            return report()
        }

        func sync(progress: ((SyncCategory) -> Void)?) async -> SyncReport {
            lock.lock(); syncCallCount += 1; lock.unlock()
            onSync?()
            return report()
        }

        private func report() -> SyncReport {
            SyncReport(statuses: SyncCategory.allCases.map {
                SyncCategoryStatus(
                    category: $0,
                    pending: 0,
                    uploaded: $0 == .meals ? uploaded : 0,
                    error: nil
                )
            })
        }
    }

    // MARK: - Utilidades

    private func makeViewModel(
        authenticated: Bool,
        router: FakeRouter = FakeRouter(),
        profileUseCase: FakeProfileUseCase = FakeProfileUseCase(),
        syncUseCase: FakeSyncUseCase = FakeSyncUseCase(),
        session: MutableSession? = nil
    ) -> ProfileViewModel {
        ProfileViewModel(
            router: router,
            userProfileUseCase: profileUseCase,
            healthUseCase: StubHealthUseCase(),
            authService: StubAuthService(),
            syncLocalDataUseCase: syncUseCase,
            session: session ?? MutableSession(authenticated)
        )
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        _ condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    // MARK: - Lo que requiere cuenta

    func testSyncStatusIsNotEvenAskedForAsGuest() async throws {
        let syncUseCase = FakeSyncUseCase()
        let viewModel = makeViewModel(authenticated: false, syncUseCase: syncUseCase)

        viewModel.loadSyncStatus()
        // Margen suficiente para que, si fuera a llamar, ya hubiera llamado.
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(syncUseCase.statusCalls, 0, "sin cuenta no se pregunta al servidor")
        XCTAssertFalse(viewModel.uiState.hasLoadedSyncStatus)
    }

    func testSyncStatusIsLoadedWithAnAccount() async throws {
        let syncUseCase = FakeSyncUseCase()
        let viewModel = makeViewModel(authenticated: true, syncUseCase: syncUseCase)

        viewModel.loadSyncStatus()
        await waitUntil { viewModel.uiState.hasLoadedSyncStatus }

        XCTAssertEqual(syncUseCase.statusCalls, 1)
        XCTAssertEqual(viewModel.uiState.syncReport.statuses.count, SyncCategory.allCases.count)
        XCTAssertFalse(viewModel.uiState.isLoadingSyncStatus, "el spinner se apaga al terminar")
    }

    func testSyncIsNotRunAsGuest() async throws {
        let syncUseCase = FakeSyncUseCase()
        let viewModel = makeViewModel(authenticated: false, syncUseCase: syncUseCase)

        viewModel.sync()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(syncUseCase.syncCalls, 0)
        XCTAssertNil(viewModel.uiState.lastSyncMessage)
    }

    func testSyncSummarisesWhatWentUp() async throws {
        let syncUseCase = FakeSyncUseCase()
        syncUseCase.uploaded = 7
        let viewModel = makeViewModel(authenticated: true, syncUseCase: syncUseCase)

        viewModel.sync()
        await waitUntil { viewModel.uiState.lastSyncMessage != nil }

        XCTAssertEqual(viewModel.uiState.lastSyncMessage, "Sincronizados 7 elementos con tu cuenta.")
        XCTAssertFalse(viewModel.uiState.isSyncing)
    }

    /// Si el token muere a mitad de la subida, el resumen no puede decir "todo al
    /// día": lo que hay que decir es que la sesión caducó.
    func testASessionThatExpiresMidSyncIsReportedAsSuch() async throws {
        let session = MutableSession(true)
        let syncUseCase = FakeSyncUseCase()
        syncUseCase.onSync = { session.set(false) }
        let viewModel = makeViewModel(authenticated: true, syncUseCase: syncUseCase, session: session)

        viewModel.sync()
        await waitUntil { viewModel.uiState.lastSyncMessage != nil }

        XCTAssertEqual(viewModel.uiState.lastSyncMessage, ProfileViewModel.sessionExpiredMessage)
    }

    // MARK: - Preferencias del coach

    func testChangingTheCoachToneIsSavedAtOnce() async throws {
        let profileUseCase = FakeProfileUseCase()
        profileUseCase.profile = makeProfile(tone: .close, detail: .normal, avoidWeightTalk: false)
        let viewModel = makeViewModel(authenticated: true, profileUseCase: profileUseCase)
        await waitUntil { viewModel.uiState.hasProfile }

        viewModel.uiState.coachTone = .technical
        viewModel.saveCoachPreferences()
        await waitUntil { profileUseCase.saved.contains { $0.coachTone == .technical } }

        XCTAssertEqual(viewModel.uiState.coachTone, .technical)
        XCTAssertNil(viewModel.uiState.coachPreferencesError)
    }

    /// Estos ajustes se guardan al tocarlos, sin botón de Guardar. Si el guardado
    /// falla y el control se queda puesto, la pantalla está diciendo que el coach ya
    /// te habla así cuando no se ha guardado nada.
    func testAFailedCoachPreferenceRevertsTheControlAndSaysSo() async throws {
        let profileUseCase = FakeProfileUseCase()
        profileUseCase.profile = makeProfile(tone: .close, detail: .normal, avoidWeightTalk: false)
        let viewModel = makeViewModel(authenticated: true, profileUseCase: profileUseCase)
        await waitUntil { viewModel.uiState.hasProfile }

        profileUseCase.saveFails = true
        viewModel.uiState.coachTone = .direct
        viewModel.saveCoachPreferences()
        await waitUntil { viewModel.uiState.coachPreferencesError != nil }

        XCTAssertEqual(
            viewModel.uiState.coachTone, .close,
            "el control vuelve a lo que sí está guardado"
        )
        XCTAssertEqual(viewModel.uiState.coachPreferencesError, "No se pudo guardar. Inténtalo de nuevo.")
    }

    func testTheAvoidWeightTalkToggleAlsoRevertsOnFailure() async throws {
        let profileUseCase = FakeProfileUseCase()
        profileUseCase.profile = makeProfile(tone: .close, detail: .normal, avoidWeightTalk: false)
        let viewModel = makeViewModel(authenticated: true, profileUseCase: profileUseCase)
        await waitUntil { viewModel.uiState.hasProfile }

        profileUseCase.saveFails = true
        viewModel.uiState.coachAvoidWeightTalk = true
        viewModel.saveCoachPreferences()
        await waitUntil { viewModel.uiState.coachPreferencesError != nil }

        XCTAssertFalse(viewModel.uiState.coachAvoidWeightTalk, "el interruptor no se queda puesto")
    }

    // MARK: - Navegación

    func testLeavingTheProfileGoesThroughTheRouter() async throws {
        let router = FakeRouter()
        let viewModel = makeViewModel(authenticated: true, router: router)

        viewModel.goToChat()
        viewModel.goToWeightProgress()
        viewModel.goToUserReport()

        XCTAssertEqual(
            router.visited, ["chat", "weight", "report"],
            "la vista ya no construye destinos: los pide al router"
        )
    }
}
