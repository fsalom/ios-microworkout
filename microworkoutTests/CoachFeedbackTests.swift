import XCTest
@testable import microworkout

/// Las señales sobre el coach: aceptó, ignoró, valoró.
///
/// Lo delicado no es enviar — es no mentir. Los dos errores que estos tests
/// vigilan: contar como "ignorada" una acción que el usuario SÍ aplicó (la señal
/// diría lo contrario de lo que pasó), y que una tarjeta servida desde caché
/// pierda sus acciones (el usuario dejaría de poder aplicarlas y todo aparecería
/// como ignorado).
final class CoachFeedbackTests: XCTestCase {

    // MARK: - Dobles

    private final class SpyFeedbackRepository: CoachFeedbackRepositoryProtocol {
        private(set) var sent: [CoachFeedbackSignal] = []
        func send(_ signal: CoachFeedbackSignal) async throws { sent.append(signal) }
    }

    private final class InMemoryStorage: UserDefaultsManagerProtocol {
        var store: [String: Data] = [:]
        private let encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return encoder
        }()
        private let decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return decoder
        }()

        func save<T: Codable>(_ object: T, forKey key: String) {
            store[key] = try? encoder.encode(object)
        }
        func get<T: Codable>(forKey key: String) -> T? {
            store[key].flatMap { try? decoder.decode(T.self, from: $0) }
        }
        func remove(forKey key: String) { store[key] = nil }
    }

    private final class StubContextUseCase: AIContextUseCaseProtocol {
        var context = AIContext()
        func buildContext(mealDaysBack: Int, healthWeeksBack: Int) async -> AIContext { context }
        func toJSON(_ context: AIContext, pretty: Bool) -> String { "{}" }
    }

    private final class StubCoachRepository: AICoachRepositoryProtocol {
        var nextInsight: CoachInsight?
        func streamCoach(
            context: AIContext, topic: AICoachTopic,
            question: String?, conversation: [AIChatTurn]
        ) -> AsyncThrowingStream<String, Error> {
            AsyncThrowingStream { $0.finish() }
        }
        func insight(context: AIContext, topic: AICoachTopic) async throws -> CoachInsight {
            guard let nextInsight else { throw DomainError.notAuthorized }
            return nextInsight
        }
    }

    private func addFood(_ name: String, grams: Double = 150) -> CoachAction {
        .addFood(CoachAction.AddFood(
            label: "Añadir \(Int(grams)) g de \(name)",
            mealType: nil,
            foodName: name,
            grams: grams,
            nutrition: NutritionInfo(calories: 200, carbohydrates: 0, proteins: 40, fats: 4)
        ))
    }

    private func insightWith(_ actions: [CoachAction], title: String = "Te falta proteína") -> CoachInsight {
        CoachInsight(
            topic: .nutrition, title: title, body: "b", prompt: "p",
            isFromModel: true, actions: actions
        )
    }

    // MARK: - Aceptar / ignorar

    func testAppliedActionIsReportedAcceptedAndRemembered() async {
        let repository = SpyFeedbackRepository()
        let storage = InMemoryStorage()
        let useCase = CoachFeedbackUseCase(repository: repository, storage: storage)
        let action = addFood("Pollo")

        await useCase.actionApplied(action, topic: .nutrition)

        XCTAssertEqual(repository.sent.count, 1)
        XCTAssertEqual(repository.sent.first?.kind, .action)
        XCTAssertEqual(repository.sent.first?.verdict, .accepted)
        XCTAssertEqual(repository.sent.first?.topic, .nutrition)
        XCTAssertEqual(repository.sent.first?.summary, "Añadir 150 g de Pollo")

        // Y al renovarse la tarjeta, esa acción NO cuenta como ignorada: decir lo
        // contrario de lo que hizo el usuario es peor que no decir nada.
        await useCase.actionsSuperseded([action, addFood("Atún")], topic: .nutrition)
        let ignored = repository.sent.filter { $0.verdict == .ignored }
        XCTAssertEqual(ignored.map(\.summary), ["Añadir 150 g de Atún"])
    }

    func testAppliedIdsAreCappedFifo() async {
        let repository = SpyFeedbackRepository()
        let storage = InMemoryStorage()
        let useCase = CoachFeedbackUseCase(repository: repository, storage: storage)

        for index in 0..<(CoachFeedbackUseCase.appliedIdsCap + 10) {
            await useCase.actionApplied(addFood("Alimento\(index)"), topic: .nutrition)
        }
        let ids: [String]? = storage.get(forKey: "coachFeedback.appliedActionIds")
        XCTAssertEqual(ids?.count, CoachFeedbackUseCase.appliedIdsCap)
        // FIFO: lo más viejo cae, lo último aplicado sigue.
        XCTAssertEqual(ids?.last, addFood("Alimento\(CoachFeedbackUseCase.appliedIdsCap + 9)").id)
        XCTAssertFalse(ids?.contains(addFood("Alimento0").id) ?? true)
    }

    // MARK: - La renovación de la tarjeta reporta las ignoradas

    func testReplacedInsightReportsUnappliedActionsAsIgnored() async throws {
        let feedbackRepository = SpyFeedbackRepository()
        let storage = InMemoryStorage()
        let feedback = CoachFeedbackUseCase(repository: feedbackRepository, storage: storage)
        let coachRepository = StubCoachRepository()
        let useCase = CoachUseCase(
            contextUseCase: StubContextUseCase(),
            repository: coachRepository,
            storage: storage,
            feedback: feedback
        )

        // Primera tarjeta, con dos propuestas. Una se aplica; la otra no.
        coachRepository.nextInsight = insightWith([addFood("Pollo"), addFood("Batido")])
        _ = await useCase.refreshInsight(for: .nutrition)
        await feedback.actionApplied(addFood("Pollo"), topic: .nutrition)

        // La tarjeta se renueva: el batido, que nunca se tocó, es la señal.
        coachRepository.nextInsight = insightWith([], title: "Vas bien")
        _ = await useCase.refreshInsight(for: .nutrition)

        // El reporte va en un Task en segundo plano para no retrasar la tarjeta.
        try await waitUntil {
            feedbackRepository.sent.contains { $0.verdict == .ignored }
        }
        let ignored = feedbackRepository.sent.filter { $0.verdict == .ignored }
        XCTAssertEqual(ignored.map(\.summary), ["Añadir 150 g de Batido"])
        XCTAssertEqual(ignored.first?.topic, .nutrition)
    }

    func testInsightWithoutActionsReportsNothingWhenReplaced() async throws {
        let feedbackRepository = SpyFeedbackRepository()
        let storage = InMemoryStorage()
        let coachRepository = StubCoachRepository()
        let useCase = CoachUseCase(
            contextUseCase: StubContextUseCase(),
            repository: coachRepository,
            storage: storage,
            feedback: CoachFeedbackUseCase(repository: feedbackRepository, storage: storage)
        )

        coachRepository.nextInsight = insightWith([])
        _ = await useCase.refreshInsight(for: .nutrition)
        coachRepository.nextInsight = insightWith([], title: "Otra")
        _ = await useCase.refreshInsight(for: .nutrition)

        // Nada que esperar: se da un margen corto y se comprueba que sigue vacío.
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(feedbackRepository.sent.isEmpty)
    }

    // MARK: - La caché conserva las acciones

    /// Una tarjeta servida desde caché tiene que conservar sus botones. Sin esto,
    /// además de perder el atajo, TODAS sus acciones acababan reportadas como
    /// ignoradas: nadie puede aplicar un botón que ya no está.
    func testCachedInsightKeepsItsActions() async {
        let storage = InMemoryStorage()
        let coachRepository = StubCoachRepository()
        let useCase = CoachUseCase(
            contextUseCase: StubContextUseCase(),
            repository: coachRepository,
            storage: storage
        )

        coachRepository.nextInsight = insightWith([addFood("Pollo")])
        let fresh = await useCase.insight(for: .nutrition)
        XCTAssertEqual(fresh.actions.count, 1)

        // Segunda lectura: mismo contexto, misma huella → sale de la caché.
        coachRepository.nextInsight = nil   // si fuese al servidor, fallaría
        let cached = await useCase.insight(for: .nutrition)
        XCTAssertTrue(cached.isFromModel)
        XCTAssertEqual(cached.actions.map(\.label), ["Añadir 150 g de Pollo"])
    }

    // MARK: - Valoraciones

    func testHeuristicInsightIsNeverRated() async {
        let repository = SpyFeedbackRepository()
        let storage = InMemoryStorage()
        let useCase = CoachUseCase(
            contextUseCase: StubContextUseCase(),
            repository: StubCoachRepository(),
            storage: storage,
            feedback: CoachFeedbackUseCase(repository: repository, storage: storage)
        )

        let local = CoachInsight(
            topic: .nutrition, title: "Local", body: "", prompt: "", isFromModel: false
        )
        await useCase.rate(local, helpful: false, reason: "da igual")
        XCTAssertTrue(repository.sent.isEmpty, "valorar el cálculo local no enseña nada a nadie")

        let fromModel = insightWith([])
        await useCase.rate(fromModel, helpful: false, reason: "muy genérico")
        XCTAssertEqual(repository.sent.first?.kind, .insight)
        XCTAssertEqual(repository.sent.first?.verdict, .unhelpful)
        XCTAssertEqual(repository.sent.first?.reason, "muy genérico")
        XCTAssertEqual(repository.sent.first?.summary, "Te falta proteína")
    }

    func testChatRatingSendsExcerptNotTheWholeAnswer() async {
        let repository = SpyFeedbackRepository()
        let useCase = CoachFeedbackUseCase(repository: repository, storage: InMemoryStorage())

        let answer = "## Análisis\n" + String(repeating: "palabra ", count: 100)
        await useCase.chatRated(topic: .daily, answer: answer, helpful: false, reason: nil)

        let signal = repository.sent.first
        XCTAssertEqual(signal?.kind, .chat)
        XCTAssertEqual(signal?.verdict, .unhelpful)
        XCTAssertEqual(signal?.topic, .daily)
        XCTAssertLessThanOrEqual(signal?.summary.count ?? 0, 200)
        XCTAssertFalse(signal?.summary.contains("\n") ?? true, "el extracto va en una línea")

        // Una respuesta vacía no es señal de nada.
        await useCase.chatRated(topic: .daily, answer: "   ", helpful: true, reason: nil)
        XCTAssertEqual(repository.sent.count, 1)
    }

    // MARK: - Helpers

    /// Espera activa con tope, para afirmaciones sobre trabajo en segundo plano.
    /// Mismo patrón que en `SyncTrackerTests`: sin orden garantizado entre el
    /// return y el Task, esperar una vez y afirmar sería una carrera.
    private func waitUntil(
        timeout: TimeInterval = 2,
        _ condition: @escaping () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline {
                XCTFail("timeout esperando la condición")
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}
