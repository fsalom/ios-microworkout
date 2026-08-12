import XCTest
@testable import microworkout

/// Buscar un alimento fallaba y la pantalla se quedaba muerta: no había forma de
/// distinguir un fallo de "no hay resultados", ni de reintentar.
///
/// Dos causas, las dos aquí fijadas:
/// - El fallo se guardaba en `uiState.error`, que **la vista no lee en ningún
///   sitio**, así que era invisible y la lista vacía decía "Sin resultados".
/// - La búsqueda solo se dispara al CAMBIAR el texto, y tras un fallo el texto que
///   querías buscar ya estaba escrito: volver a teclearlo no disparaba nada.
final class AddMealSearchTests: XCTestCase {

    // MARK: - Dobles

    private enum Boom: Error { case offline }

    private struct StubRouter: AddMealRouterProtocol {
        func goToBarcodeScannerView(onScanComplete: @escaping (FoodItem) -> Void) {}
        func goBack() {}
    }

    private final class FakeMealUseCase: MealUseCaseProtocol, @unchecked Sendable {
        private let lock = NSLock()
        private var searchCallCount = 0
        var searchFails = false
        var results: [FoodItem] = []

        var searchCalls: Int { lock.lock(); defer { lock.unlock() }; return searchCallCount }

        func searchFoods(query: String) async throws -> [FoodItem] {
            lock.lock(); searchCallCount += 1; let fails = searchFails; lock.unlock()
            if fails { throw Boom.offline }
            return results
        }

        // Lo demás no participa en esta prueba.
        func saveMeal(_ meal: Meal) async throws {}
        func getMealsForToday() async throws -> [Meal] { [] }
        func getMeals(for date: Date) async throws -> [Meal] { [] }
        func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] { [] }
        func deleteMeal(_ mealId: UUID) async throws {}
        func fetchFoodByBarcode(_ barcode: String) async throws -> FoodItem? { nil }
        func getTodayTotals() async throws -> NutritionInfo { .zero }
        func getRecentFoods(limit: Int) async throws -> [FoodItem] { [] }
        func getFavorites() async throws -> [FoodItem] { [] }
        func isFavorite(_ food: FoodItem, in favorites: [FoodItem]) -> Bool { false }
        func toggleFavorite(_ food: FoodItem) async throws {}
        func getMyMeals() async throws -> [MyMeal] { [] }
        func saveMyMeal(_ myMeal: MyMeal) async throws {}
        func deleteMyMeal(id: UUID) async throws {}
        func saveCustomFood(_ food: FoodItem) {}
        func getCustomFood(barcode: String) -> FoodItem? { nil }
    }

    private func makeViewModel(_ useCase: FakeMealUseCase) -> AddMealViewModel {
        AddMealViewModel(router: StubRouter(), mealUseCase: useCase)
    }

    private func waitUntil(
        timeout: TimeInterval = 3,
        _ condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    // MARK: - Un fallo se ve y se puede reintentar

    func testAFailedSearchIsReportedInsteadOfLookingLikeNoResults() async throws {
        let useCase = FakeMealUseCase()
        useCase.searchFails = true
        let viewModel = makeViewModel(useCase)

        viewModel.uiState.searchQuery = "pollo"
        viewModel.searchFoods()
        // Se espera por las DOS condiciones: el aviso se pone en el `catch` y el
        // spinner se apaga en un `Task` aparte, así que entre uno y otro hay una
        // ventana. Esperar solo por el aviso hacía este test flaky.
        await waitUntil {
            viewModel.uiState.searchError != nil && !viewModel.uiState.isSearching
        }

        XCTAssertNotNil(viewModel.uiState.searchError, "el fallo tiene que salir a la UI")
        XCTAssertTrue(viewModel.uiState.searchResults.isEmpty)
        XCTAssertFalse(viewModel.uiState.isSearching, "y el spinner se apaga")
    }

    /// Lo que desbloquea la pantalla: reintentar sin tocar el texto.
    func testRetryRunsTheSearchAgainWithoutChangingTheText() async throws {
        let useCase = FakeMealUseCase()
        useCase.searchFails = true
        let viewModel = makeViewModel(useCase)

        viewModel.uiState.searchQuery = "pollo"
        viewModel.searchFoods()
        await waitUntil { viewModel.uiState.searchError != nil }
        XCTAssertEqual(useCase.searchCalls, 1)

        // Vuelve la red y el usuario reintenta, con el mismo texto en el campo.
        useCase.searchFails = false
        useCase.results = [FoodItem(name: "Pollo")]
        viewModel.retrySearch()
        await waitUntil { !viewModel.uiState.searchResults.isEmpty }

        XCTAssertEqual(useCase.searchCalls, 2, "el reintento vuelve a preguntar")
        XCTAssertEqual(viewModel.uiState.searchResults.map(\.name), ["Pollo"])
        XCTAssertNil(viewModel.uiState.searchError, "y el aviso desaparece")
    }

    func testTheErrorIsClearedWhenANewSearchStarts() async throws {
        let useCase = FakeMealUseCase()
        useCase.searchFails = true
        let viewModel = makeViewModel(useCase)

        viewModel.uiState.searchQuery = "pollo"
        viewModel.searchFoods()
        await waitUntil { viewModel.uiState.searchError != nil }

        useCase.searchFails = false
        viewModel.uiState.searchQuery = "merluza"
        viewModel.searchFoods()

        XCTAssertNil(
            viewModel.uiState.searchError,
            "el aviso del intento anterior no puede quedarse mientras carga el nuevo"
        )
    }

    /// Borrar el texto deja la búsqueda limpia, sin aviso pegado.
    func testClearingTheQueryAlsoClearsTheError() async throws {
        let useCase = FakeMealUseCase()
        useCase.searchFails = true
        let viewModel = makeViewModel(useCase)

        viewModel.uiState.searchQuery = "pollo"
        viewModel.searchFoods()
        await waitUntil { viewModel.uiState.searchError != nil }

        viewModel.uiState.searchQuery = "p"   // menos de 2 caracteres
        viewModel.searchFoods()

        XCTAssertNil(viewModel.uiState.searchError)
        XCTAssertTrue(viewModel.uiState.searchResults.isEmpty)
    }

    /// La búsqueda es estado COMPARTIDO con la hoja de "Mi comida". Al cerrarla se
    /// limpiaba `uiState` a mano, sin cancelar la tarea en vuelo: podía terminar
    /// después y repoblar los resultados de una consulta que ya no existía.
    func testResettingTheSharedSearchDropsAnInFlightResult() async throws {
        let useCase = FakeMealUseCase()
        useCase.results = [FoodItem(name: "Fantasma")]
        let viewModel = makeViewModel(useCase)

        viewModel.uiState.searchQuery = "pollo"
        viewModel.searchFoods()
        // Se cierra la hoja mientras la búsqueda está en vuelo.
        viewModel.resetSharedSearch()

        // Margen de sobra para que la búsqueda hubiera terminado.
        try? await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertTrue(
            viewModel.uiState.searchResults.isEmpty,
            "un resultado que llega tarde no puede repoblar la búsqueda ya cerrada"
        )
        XCTAssertEqual(viewModel.uiState.searchQuery, "")
        XCTAssertFalse(viewModel.uiState.isSearching)
    }
}
