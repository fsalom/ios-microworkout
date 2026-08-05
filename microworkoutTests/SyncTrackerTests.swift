import XCTest
@testable import microworkout

/// La subida automática al iniciar sesión se dispara desde `RootView`, que puede
/// ver el mismo cambio de estado más de una vez. El tracker es quien garantiza
/// que solo haya una subida en curso y quien alimenta el banner.
@MainActor
final class SyncTrackerTests: XCTestCase {

    private final class FakeSyncUseCase: SyncLocalDataUseCaseProtocol {
        var syncCalls = 0
        var reportedCategories: [SyncCategory] = []
        /// Se libera para que el test controle cuándo termina la subida.
        var gate = AsyncGate()
        var uploaded = 3
        var hasErrors = false

        func status() async -> SyncReport { .empty() }

        func sync(progress: ((SyncCategory) -> Void)?) async -> SyncReport {
            syncCalls += 1
            for category in SyncCategory.allCases {
                progress?(category)
                reportedCategories.append(category)
            }
            await gate.wait()
            return SyncReport(statuses: SyncCategory.allCases.map { category in
                SyncCategoryStatus(
                    category: category,
                    pending: hasErrors ? 1 : 0,
                    uploaded: category == .meals ? uploaded : 0,
                    error: hasErrors && category == .meals ? "boom" : nil
                )
            })
        }
    }

    /// Semáforo mínimo para que el test decida cuándo acaba la subida.
    private actor AsyncGate {
        private var isOpen = false
        private var waiters: [CheckedContinuation<Void, Never>] = []

        func open() {
            isOpen = true
            waiters.forEach { $0.resume() }
            waiters.removeAll()
        }

        func wait() async {
            if isOpen { return }
            await withCheckedContinuation { waiters.append($0) }
        }
    }

    override func setUp() async throws {
        // El tracker es un singleton: se deja en reposo antes de cada test.
        await waitUntil { SyncTracker.shared.phase == .idle }
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        _ condition: @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    func testBannerReportsEachCategoryWhileSyncing() async throws {
        let useCase = FakeSyncUseCase()
        SyncTracker.shared.syncAfterLogin(using: useCase)

        await waitUntil { SyncTracker.shared.isVisible }
        XCTAssertTrue(SyncTracker.shared.isVisible, "el banner debe aparecer al arrancar")

        await useCase.gate.open()
        await waitUntil {
            if case .finished = SyncTracker.shared.phase { return true }
            return false
        }

        XCTAssertEqual(
            useCase.reportedCategories, SyncCategory.allCases,
            "debe informar de todas las categorías, en orden"
        )
        XCTAssertEqual(SyncTracker.shared.phase, .finished(uploaded: 3, hasErrors: false))
    }

    func testASecondLoginWhileSyncingDoesNotStartAnotherUpload() async throws {
        let useCase = FakeSyncUseCase()
        SyncTracker.shared.syncAfterLogin(using: useCase)
        await waitUntil { SyncTracker.shared.isVisible }

        // RootView puede ver el mismo cambio de estado dos veces.
        SyncTracker.shared.syncAfterLogin(using: useCase)
        SyncTracker.shared.syncAfterLogin(using: useCase)

        await useCase.gate.open()
        await waitUntil {
            if case .finished = SyncTracker.shared.phase { return true }
            return false
        }
        XCTAssertEqual(useCase.syncCalls, 1, "solo una subida en curso")
    }

    func testErrorsAreSurfacedInTheBanner() async throws {
        let useCase = FakeSyncUseCase()
        useCase.hasErrors = true
        SyncTracker.shared.syncAfterLogin(using: useCase)
        await useCase.gate.open()

        await waitUntil {
            if case .finished = SyncTracker.shared.phase { return true }
            return false
        }
        XCTAssertEqual(SyncTracker.shared.phase, .finished(uploaded: 3, hasErrors: true))
    }
}
