import XCTest
@testable import microworkout

/// El coach propone acciones y la app las ejecuta cuando el usuario confirma.
///
/// Lo delicado es la conversión de macros: el coach los manda de la CANTIDAD que
/// propone ("150 g de pollo son 248 kcal"), pero `FoodItem` los guarda por 100 g y
/// los reescala al pintar. Si no se convierte, añadir 150 g registra los macros de
/// 150 g multiplicados otra vez por 1,5 — y nadie lo nota hasta que los totales del
/// día no cuadran.
final class CoachActionTests: XCTestCase {

    private final class FakeMealUseCase: MealUseCaseProtocol, @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [Meal] = []
        var saveFails = false

        var saved: [Meal] { lock.lock(); defer { lock.unlock() }; return stored }

        func saveMeal(_ meal: Meal) async throws {
            if saveFails { throw DomainError.notFound }
            lock.lock(); stored.append(meal); lock.unlock()
        }

        func getMealsForToday() async throws -> [Meal] { [] }
        func getMeals(for date: Date) async throws -> [Meal] { [] }
        func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] { [] }
        func deleteMeal(_ mealId: UUID) async throws {}
        func fetchFoodByBarcode(_ barcode: String) async throws -> FoodItem? { nil }
        func searchFoods(query: String) async throws -> [FoodItem] { [] }
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

    private func addChicken(grams: Double = 150, mealType: MealType? = .dinner) -> CoachAction {
        .addFood(
            CoachAction.AddFood(
                label: "Añadir 150 g de pollo",
                mealType: mealType,
                foodName: "Pechuga de pollo",
                grams: grams,
                // Macros de ESOS 150 g, que es como los manda el coach.
                nutrition: NutritionInfo(
                    calories: 248, carbohydrates: 0, proteins: 47, fats: 5, fiber: nil
                )
            )
        )
    }

    // MARK: - Lo que se registra es lo que dijo el coach

    func testTheFoodIsLoggedWithExactlyTheMacrosTheCoachProposed() async throws {
        let meals = FakeMealUseCase()
        let useCase = CoachActionUseCase(mealUseCase: meals)

        let message = try await useCase.apply(addChicken())

        let meal = try XCTUnwrap(meals.saved.first)
        let item = try XCTUnwrap(meal.items.first)
        XCTAssertEqual(item.name, "Pechuga de pollo")
        XCTAssertEqual(item.quantity, 150)

        // Lo que cuenta para el día es `actualNutrition`, y tiene que devolver
        // EXACTAMENTE lo que propuso el coach.
        XCTAssertEqual(item.actualNutrition.calories, 248, accuracy: 0.01)
        XCTAssertEqual(item.actualNutrition.proteins, 47, accuracy: 0.01)
        XCTAssertEqual(item.actualNutrition.fats, 5, accuracy: 0.01)
        XCTAssertEqual(message, "Añadido: Pechuga de pollo, 150 g")
    }

    /// La conversión intermedia: por dentro se guarda por 100 g.
    func testMacrosAreStoredPer100gSoTheQuantityCanChangeLater() async throws {
        let meals = FakeMealUseCase()
        let useCase = CoachActionUseCase(mealUseCase: meals)

        _ = try await useCase.apply(addChicken())

        let item = try XCTUnwrap(meals.saved.first?.items.first)
        // 248 kcal en 150 g son 165,33 por 100 g.
        XCTAssertEqual(item.nutritionPer100g.calories, 165.33, accuracy: 0.01)
        XCTAssertEqual(item.nutritionPer100g.proteins, 31.33, accuracy: 0.01)
    }

    /// Y sigue cuadrando con una cantidad que no sea 100 ni 150.
    func testTheConversionHoldsForAnyQuantity() async throws {
        let meals = FakeMealUseCase()
        let useCase = CoachActionUseCase(mealUseCase: meals)

        _ = try await useCase.apply(addChicken(grams: 37))

        let item = try XCTUnwrap(meals.saved.first?.items.first)
        XCTAssertEqual(item.actualNutrition.calories, 248, accuracy: 0.01)
    }

    // MARK: - A qué comida va

    func testItGoesToTheMealTheCoachSaid() async throws {
        let meals = FakeMealUseCase()
        _ = try await CoachActionUseCase(mealUseCase: meals).apply(addChicken(mealType: .dinner))
        XCTAssertEqual(meals.saved.first?.type, .dinner)
    }

    /// Sin comida indicada, la que toque por la hora: es mejor acertar casi siempre
    /// que dejarlo caer en una fija.
    func testWithoutAMealTypeItUsesTheOneForTheCurrentTime() async throws {
        let meals = FakeMealUseCase()
        _ = try await CoachActionUseCase(mealUseCase: meals).apply(addChicken(mealType: nil))
        XCTAssertEqual(meals.saved.first?.type, MealType.forCurrentTime())
    }

    func testAFailureToSaveIsPropagatedSoTheScreenCanSayIt() async throws {
        let meals = FakeMealUseCase()
        meals.saveFails = true

        do {
            _ = try await CoachActionUseCase(mealUseCase: meals).apply(addChicken())
            XCTFail("un fallo al guardar no se puede tragar")
        } catch {
            XCTAssertTrue(meals.saved.isEmpty)
        }
    }

    // MARK: - Contrato de red

    /// Una acción de un tipo que la app no sabe ejecutar se descarta al mapear, en
    /// vez de llegar a la pantalla como un botón que no hace nada.
    func testAnUnknownActionTypeIsDropped() throws {
        let json = """
        {"topic": "nutrition", "title": "t", "body": "b", "bullets": [], "prompt": "p",
         "actions": [
           {"type": "borrar_todo", "label": "Borrar"},
           {"type": "add_food", "label": "Añadir 150 g de pollo",
            "meal_type": "Cena", "food_name": "Pollo", "grams": 150,
            "calories": 248, "protein_g": 47, "carbs_g": 0, "fat_g": 5}
         ]}
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(AIInsightApiDTO.self, from: json)
        let insight = dto.toDomain(fallbackTopic: .nutrition)

        XCTAssertEqual(insight.actions.count, 1, "solo sobrevive la que se sabe ejecutar")
        XCTAssertEqual(insight.actions.first?.label, "Añadir 150 g de pollo")
    }

    /// Sin gramos no hay acción: un botón "añadir pollo" que no sabe cuánto
    /// registraría cualquier cosa.
    func testAnAddFoodWithoutGramsIsDropped() throws {
        let json = """
        {"topic": "nutrition", "title": "t", "body": "b", "bullets": [], "prompt": "p",
         "actions": [{"type": "add_food", "label": "Añadir pollo", "food_name": "Pollo"}]}
        """.data(using: .utf8)!

        let insight = try JSONDecoder()
            .decode(AIInsightApiDTO.self, from: json).toDomain(fallbackTopic: .nutrition)
        XCTAssertTrue(insight.actions.isEmpty)
    }

    /// Un backend anterior no manda `actions`, y la tarjeta sigue siendo válida.
    func testAnInsightWithoutActionsStillDecodes() throws {
        let json = """
        {"topic": "nutrition", "title": "t", "body": "b", "bullets": [], "prompt": "p"}
        """.data(using: .utf8)!

        let insight = try JSONDecoder()
            .decode(AIInsightApiDTO.self, from: json).toDomain(fallbackTopic: .nutrition)
        XCTAssertTrue(insight.actions.isEmpty)
    }
}
