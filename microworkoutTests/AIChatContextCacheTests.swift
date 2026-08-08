import XCTest
@testable import microworkout

/// Construir el contexto del chat es la operación cara de la pantalla: lee el
/// perfil, todo el histórico de entrenos, las comidas y HealthKit. Se hace UNA vez
/// por pantalla, y ese "una vez" es lo que se fija aquí.
@MainActor
final class AIChatContextCacheTests: XCTestCase {

    private final class CountingContextUseCase: AIContextUseCaseProtocol, @unchecked Sendable {
        private let lock = NSLock()
        private var calls = 0
        /// Retraso simulado: sin él las dos llamadas del test no se solaparían y el
        /// caso que importa (dos entradas a la vez) no se probaría.
        var delay: Duration = .milliseconds(150)

        var buildCalls: Int { lock.lock(); defer { lock.unlock() }; return calls }

        func buildContext(mealDaysBack: Int, healthWeeksBack: Int) async -> AIContext {
            lock.lock(); calls += 1; lock.unlock()
            try? await Task.sleep(for: delay)
            return AIContext(
                generatedAt: Date(),
                locale: "es_ES",
                profile: nil,
                workoutSessions: [],
                workoutLogs: [],
                manualEntries: [],
                meals: [],
                healthDays: [],
                healthWorkouts: []
            )
        }

        func toJSON(_ context: AIContext, pretty: Bool) -> String { "{}" }
    }

    private struct SilentChatUseCase: AICoachChatUseCaseProtocol {
        func stream(
            context: AIContext,
            question: String,
            topic: AICoachTopic,
            conversation: [AIChatTurn]
        ) -> AsyncThrowingStream<String, Error> {
            AsyncThrowingStream { $0.finish() }
        }
    }

    private func waitUntil(
        timeout: TimeInterval = 3,
        _ condition: @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    /// Abrir la hoja de datos y mandar un mensaje a la vez entraba dos veces a
    /// construir el contexto: las dos veían la caché vacía porque la comprobación y
    /// el guardado no estaban aislados. Coste: leer HealthKit y todo el histórico
    /// por duplicado.
    func testTwoSimultaneousEntrantsShareOneContextBuild() async throws {
        let contextUseCase = CountingContextUseCase()
        let viewModel = AIChatViewModel(
            contextUseCase: contextUseCase,
            chatUseCase: SilentChatUseCase(),
            topic: .free
        )

        // Las dos entradas al contexto que hay en la pantalla, a la vez.
        viewModel.openContextSheet()
        viewModel.uiState.input = "¿qué tal voy?"
        viewModel.send()

        await waitUntil { viewModel.uiState.isContextReady && !viewModel.uiState.isStreaming }

        XCTAssertEqual(
            contextUseCase.buildCalls, 1,
            "quien llega segundo espera la construcción en curso, no lanza otra"
        )
    }

    func testTheContextIsReusedAcrossTurns() async throws {
        let contextUseCase = CountingContextUseCase()
        contextUseCase.delay = .zero
        let viewModel = AIChatViewModel(
            contextUseCase: contextUseCase,
            chatUseCase: SilentChatUseCase(),
            topic: .free
        )

        for question in ["uno", "dos", "tres"] {
            viewModel.uiState.input = question
            viewModel.send()
            await waitUntil { !viewModel.uiState.isStreaming }
        }

        XCTAssertEqual(
            contextUseCase.buildCalls, 1,
            "entre turno y turno el contexto no cambia: no se reconstruye"
        )
    }
}
