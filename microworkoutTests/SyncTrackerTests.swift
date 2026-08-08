import XCTest
import Combine
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

    /// Tracker propio por test, y no `tracker`: el singleton arrastra
    /// estado entre tests y su banner se esconde solo a los 3,5 s, así que la
    /// comprobación competía contra un reloj de pared y fallaba en cuanto la
    /// máquina iba cargada. Una ventana larga hace la prueba determinista.
    private func makeTracker() -> SyncTracker {
        SyncTracker(visibleAfterFinish: .seconds(600))
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

    // Ya no hace falta un `setUp` que espere a que el singleton vuelva a reposo:
    // cada test tiene su propio tracker y arranca en `.idle` por construcción.

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
        let tracker = makeTracker()
        let useCase = FakeSyncUseCase()
        tracker.syncAfterLogin(using: useCase)

        await waitUntil { tracker.isVisible }
        XCTAssertTrue(tracker.isVisible, "el banner debe aparecer al arrancar")

        await useCase.gate.open()
        await waitUntil {
            if case .finished = tracker.phase { return true }
            return false
        }

        XCTAssertEqual(
            useCase.reportedCategories, SyncCategory.allCases,
            "debe informar de todas las categorías, en orden"
        )
        XCTAssertEqual(tracker.phase, .finished(uploaded: 3, hasErrors: false))
    }

    func testASecondLoginWhileSyncingDoesNotStartAnotherUpload() async throws {
        let tracker = makeTracker()
        let useCase = FakeSyncUseCase()
        tracker.syncAfterLogin(using: useCase)
        await waitUntil { tracker.isVisible }

        // RootView puede ver el mismo cambio de estado dos veces.
        tracker.syncAfterLogin(using: useCase)
        tracker.syncAfterLogin(using: useCase)

        await useCase.gate.open()
        await waitUntil {
            if case .finished = tracker.phase { return true }
            return false
        }
        XCTAssertEqual(useCase.syncCalls, 1, "solo una subida en curso")
    }

    /// Cada categoría debe anunciarse con SU número de orden.
    ///
    /// El contador vivía en un `var` capturado por el `Task` del tracker (aislado
    /// al main actor) pero lo incrementaba el caso de uso desde otro hilo: además
    /// de ser una carrera, el salto al main actor lo leía ya incrementado y el
    /// banner enseñaba siempre una categoría de más — "2 de 6" mientras subía el
    /// perfil, y nunca "1 de 6".
    func testEachCategoryIsAnnouncedWithItsOwnPosition() async throws {
        final class Seen { var pairs: [(SyncCategory, Int)] = [] }
        let seen = Seen()

        let tracker = makeTracker()
        let useCase = FakeSyncUseCase()
        let cancellable = tracker.$phase.sink { phase in
            if case .syncing(let category, let done, _) = phase {
                seen.pairs.append((category, done))
            }
        }
        defer { cancellable.cancel() }

        tracker.syncAfterLogin(using: useCase)
        await useCase.gate.open()
        await waitUntil {
            if case .finished = tracker.phase { return true }
            return false
        }

        XCTAssertEqual(
            Set(seen.pairs.map { $0.0 }), Set(SyncCategory.allCases),
            "todas las categorías se anuncian"
        )
        for (category, done) in seen.pairs {
            XCTAssertEqual(
                done, SyncCategory.allCases.firstIndex(of: category),
                "\(category.title) se anunció como la número \(done + 1)"
            )
        }
    }

    func testErrorsAreSurfacedInTheBanner() async throws {
        let tracker = makeTracker()
        let useCase = FakeSyncUseCase()
        useCase.hasErrors = true
        tracker.syncAfterLogin(using: useCase)
        await useCase.gate.open()

        await waitUntil {
            if case .finished = tracker.phase { return true }
            return false
        }
        XCTAssertEqual(tracker.phase, .finished(uploaded: 3, hasErrors: true))
    }
}
