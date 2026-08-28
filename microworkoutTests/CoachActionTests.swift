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

    private final class SpyProgressionStore: ProgressionSuggestionStoreProtocol {
        private(set) var saved: [ProgressionSuggestion] = []
        func save(_ suggestion: ProgressionSuggestion) { saved.append(suggestion) }
        func suggestion(for exerciseName: String) -> ProgressionSuggestion? {
            saved.last {
                $0.exerciseName.lowercased() == exerciseName.lowercased()
            }
        }
    }

    func testTheFoodIsLoggedWithExactlyTheMacrosTheCoachProposed() async throws {
        let meals = FakeMealUseCase()
        let useCase = CoachActionUseCase(mealUseCase: meals, progressionStore: SpyProgressionStore())

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
        let useCase = CoachActionUseCase(mealUseCase: meals, progressionStore: SpyProgressionStore())

        _ = try await useCase.apply(addChicken())

        let item = try XCTUnwrap(meals.saved.first?.items.first)
        // 248 kcal en 150 g son 165,33 por 100 g.
        XCTAssertEqual(item.nutritionPer100g.calories, 165.33, accuracy: 0.01)
        XCTAssertEqual(item.nutritionPer100g.proteins, 31.33, accuracy: 0.01)
    }

    /// Y sigue cuadrando con una cantidad que no sea 100 ni 150.
    func testTheConversionHoldsForAnyQuantity() async throws {
        let meals = FakeMealUseCase()
        let useCase = CoachActionUseCase(mealUseCase: meals, progressionStore: SpyProgressionStore())

        _ = try await useCase.apply(addChicken(grams: 37))

        let item = try XCTUnwrap(meals.saved.first?.items.first)
        XCTAssertEqual(item.actualNutrition.calories, 248, accuracy: 0.01)
    }

    // MARK: - A qué comida va

    func testItGoesToTheMealTheCoachSaid() async throws {
        let meals = FakeMealUseCase()
        _ = try await CoachActionUseCase(mealUseCase: meals, progressionStore: SpyProgressionStore()).apply(addChicken(mealType: .dinner))
        XCTAssertEqual(meals.saved.first?.type, .dinner)
    }

    /// Sin comida indicada, la que toque por la hora: es mejor acertar casi siempre
    /// que dejarlo caer en una fija.
    func testWithoutAMealTypeItUsesTheOneForTheCurrentTime() async throws {
        let meals = FakeMealUseCase()
        _ = try await CoachActionUseCase(mealUseCase: meals, progressionStore: SpyProgressionStore()).apply(addChicken(mealType: nil))
        XCTAssertEqual(meals.saved.first?.type, MealType.forCurrentTime())
    }

    func testAFailureToSaveIsPropagatedSoTheScreenCanSayIt() async throws {
        let meals = FakeMealUseCase()
        meals.saveFails = true

        do {
            _ = try await CoachActionUseCase(mealUseCase: meals, progressionStore: SpyProgressionStore()).apply(addChicken())
            XCTFail("un fallo al guardar no se puede tragar")
        } catch {
            XCTAssertTrue(meals.saved.isEmpty)
        }
    }

    // MARK: - Contrato de red

    /// Una acción de un tipo que la app no sabe ejecutar se descarta al mapear, en
    /// vez de llegar a la pantalla como un botón que no hace nada.
    // MARK: - Objetivos de progresión

    private final class InMemoryStorage: UserDefaultsManagerProtocol {
        var store: [String: Data] = [:]
        func save<T: Codable>(_ object: T, forKey key: String) {
            let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
            store[key] = try? encoder.encode(object)
        }
        func get<T: Codable>(forKey key: String) -> T? {
            let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
            return store[key].flatMap { try? decoder.decode(T.self, from: $0) }
        }
        func remove(forKey key: String) { store[key] = nil }
    }

    /// El coach escribe el nombre como lo vio ("Press banca"); la pantalla pregunta
    /// con el nombre del ejercicio del usuario, que puede variar en mayúsculas o
    /// espacios. Y un objetivo de hace 15 días ya no describe tu estado.
    func testStoreNormalizesNamesAndExpiresOldTargets() {
        let store = ProgressionSuggestionStore(storage: InMemoryStorage())

        store.save(ProgressionSuggestion(
            exerciseName: "Press banca", weightKg: 62.5, reps: 8, sets: nil, savedAt: Date()
        ))
        XCTAssertNotNil(store.suggestion(for: "  press BANCA "))
        XCTAssertNil(store.suggestion(for: "Sentadilla"))

        store.save(ProgressionSuggestion(
            exerciseName: "Sentadilla", weightKg: 100, reps: 5, sets: nil,
            savedAt: Date().addingTimeInterval(-15 * 86_400)
        ))
        XCTAssertNil(store.suggestion(for: "Sentadilla"), "caducado a los 14 días")
    }


    /// Aplicar la propuesta la guarda con el nombre EXACTO del ejercicio: es la
    /// clave con la que la pantalla de registro la buscará.
    func testApplyingAProgressionStoresTheTarget() async throws {
        let store = SpyProgressionStore()
        let useCase = CoachActionUseCase(mealUseCase: FakeMealUseCase(), progressionStore: store)

        let confirmation = try await useCase.apply(.suggestProgression(CoachAction.Progression(
            label: "Banca: 62,5 kg × 8", exerciseName: "Press banca",
            weightKg: 62.5, reps: 8, sets: 3
        )))

        XCTAssertEqual(store.saved.count, 1)
        XCTAssertEqual(store.saved.first?.exerciseName, "Press banca")
        XCTAssertEqual(store.saved.first?.weightKg, 62.5)
        XCTAssertTrue(confirmation.contains("62,5 kg × 8"))
    }

    func testProgressionDecodesFromBackendKeys() throws {
        let json = """
        {"type": "suggest_progression", "label": "Banca: 62,5 kg × 8",
         "exercise_name": "Press banca", "weight_kg": 62.5, "reps": 8, "sets": 3}
        """
        let action = try JSONDecoder()
            .decode(AIActionApiDTO.self, from: Data(json.utf8)).toDomain()
        guard case .suggestProgression(let progression) = action else {
            return XCTFail("debía ser una progresión, es \(String(describing: action))")
        }
        XCTAssertEqual(progression.exerciseName, "Press banca")
        XCTAssertEqual(progression.reps, 8)
    }

    /// "Progresa en banca" sin peso ni reps es un consejo, no una acción.
    func testProgressionWithoutAnyTargetIsDropped() throws {
        let json = """
        {"type": "suggest_progression", "label": "Progresa", "exercise_name": "Press banca", "sets": 3}
        """
        XCTAssertNil(try JSONDecoder().decode(AIActionApiDTO.self, from: Data(json.utf8)).toDomain())
    }

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
