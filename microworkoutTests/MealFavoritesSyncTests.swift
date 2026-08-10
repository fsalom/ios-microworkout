import XCTest
@testable import microworkout

/// Los alimentos añadidos como invitado desaparecían de "Favoritos" al iniciar
/// sesión: la lectura pasaba a ser solo-servidor y la sincronización de login no
/// los subía. Estos tests fijan que convivan.
///
/// La sesión se INYECTA en el repositorio (`StubSession`) en vez de tocar
/// `AuthSession.shared`: ese singleton lo comparte toda la suite y, con los tests
/// corriendo en paralelo, cambiarlo hacía fallar a otra clase.
final class MealFavoritesSyncTests: XCTestCase {

    // MARK: - Dobles

    private final class FakeRemote: MealRemoteDataSourceProtocol {
        var favorites: [FoodApiDTO] = []
        var foodsByBarcode: [String: FoodApiDTO] = [:]
        var createdFoods: [FoodItem] = []
        var addedFavoriteIds: [UUID] = []
        var removedFavoriteIds: [UUID] = []
        /// Ids que el servidor asigna al crear, en orden.
        var idsToAssign: [UUID] = []
        var meals: [MealApiDTO] = []
        var myMeals: [MyMealApiDTO] = []
        var isOffline = false
        private(set) var createdMeals: [Meal] = []
        private(set) var createdMyMeals: [MyMeal] = []
        private(set) var deletedMyMealIds: [UUID] = []

        func createMeal(_ meal: Meal) async throws -> MealApiDTO {
            if isOffline { throw Fake.unused }
            createdMeals.append(meal)
            return MealApiDTO(
                id: meal.id, type: meal.type.rawValue,
                timestamp: meal.timestamp, items: [], myMealName: meal.myMealName
            )
        }
        func listMeals(for date: Date) async throws -> [MealApiDTO] { meals }
        func listMeals(from start: Date, to end: Date) async throws -> [MealApiDTO] { meals }
        func deleteMeal(id: UUID) async throws {}

        func foodByBarcode(_ barcode: String) async throws -> FoodApiDTO? {
            foodsByBarcode[barcode]
        }

        func listFavorites() async throws -> [FoodApiDTO] { favorites }

        func addFavorite(foodId: UUID) async throws {
            // El servidor solo conoce ids que existen en su BD.
            let known = Set(favorites.compactMap { $0.id })
                .union(foodsByBarcode.values.compactMap { $0.id })
                .union(idsAssigned)
            guard known.contains(foodId) else { throw Fake.unknownFood }
            addedFavoriteIds.append(foodId)
        }

        func removeFavorite(foodId: UUID) async throws { removedFavoriteIds.append(foodId) }

        private var idsAssigned: [UUID] = []

        func createCustomFood(_ food: FoodItem) async throws -> FoodApiDTO {
            createdFoods.append(food)
            // Igual que el backend: la BD genera el id, NO se reutiliza el del cliente.
            let assigned = idsToAssign.isEmpty ? UUID() : idsToAssign.removeFirst()
            idsAssigned.append(assigned)
            return FoodApiDTO(
                id: assigned,
                name: food.name,
                barcode: food.barcode,
                nutritionPer100g: NutritionInfoApiDTO(
                    calories: 0, carbohydrates: 0, proteins: 0, fats: 0, fiber: nil
                ),
                servingSize: nil,
                imageUrl: nil
            )
        }

        func listMyMeals() async throws -> [MyMealApiDTO] {
            if isOffline { throw Fake.unused }
            return myMeals
        }
        func createMyMeal(_ myMeal: MyMeal) async throws -> MyMealApiDTO {
            if isOffline { throw Fake.unused }
            createdMyMeals.append(myMeal)
            return MyMealApiDTO(id: myMeal.id, name: myMeal.name, items: [])
        }
        func deleteMyMeal(id: UUID) async throws { deletedMyMealIds.append(id) }
    }

    private enum Fake: Error { case unused, unknownFood }

    private final class FakeLocal: MealDataSourceProtocol {
        var favorites: [FoodItemDTO] = []
        var myMeals: [MyMealDTO] = []
        var meals: [MealDTO] = []
        var customFoods: [String: FoodItemDTO] = [:]

        // Filtran por fecha como el `MealLocalDataSource` de verdad. Antes devolvían
        // TODO ignorando el parámetro, así que ninguna prueba de comidas ejercitaba
        // el filtrado por día — justo donde una comida puede desaparecer de la
        // pantalla estando guardada.
        func saveMeal(_ meal: MealDTO) async throws { meals.append(meal) }
        func getMeals(for date: Date) async throws -> [MealDTO] {
            meals.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
        }
        func getMeals(from startDate: Date, to endDate: Date) async throws -> [MealDTO] {
            let start = Calendar.current.startOfDay(for: startDate)
            return meals.filter { $0.timestamp >= start && $0.timestamp <= endDate }
        }
        func getAllMeals() async throws -> [MealDTO] { meals }
        func deleteMeal(_ mealId: UUID) async throws { meals.removeAll { $0.id == mealId } }
        func getFavorites() -> [FoodItemDTO] { favorites }
        func saveFavorites(_ favorites: [FoodItemDTO]) { self.favorites = favorites }
        func getMyMeals() -> [MyMealDTO] { myMeals }
        func saveMyMeals(_ meals: [MyMealDTO]) { myMeals = meals }
        func getCustomFoods() -> [String: FoodItemDTO] { customFoods }
        func saveCustomFoods(_ foods: [String: FoodItemDTO]) { customFoods = foods }
    }

    private final class FakeOpenFoodFacts: OpenFoodFactsApiProtocol {
        func fetchProduct(barcode: String) async throws -> OpenFoodFactsProductDTO? { nil }
        func searchProducts(query: String, page: Int, pageSize: Int) async throws -> [OpenFoodFactsProductDTO] { [] }
    }

    // MARK: - Utilidades

    private func food(_ name: String, barcode: String? = nil) -> FoodItem {
        FoodItem(name: name, barcode: barcode)
    }

    private func dto(_ id: UUID, _ name: String, barcode: String? = nil) -> FoodApiDTO {
        FoodApiDTO(
            id: id, name: name, barcode: barcode,
            nutritionPer100g: NutritionInfoApiDTO(
                calories: 0, carbohydrates: 0, proteins: 0, fats: 0, fiber: nil
            ),
            servingSize: nil, imageUrl: nil
        )
    }

    private func makeRepository(
        local: FakeLocal, remote: FakeRemote, authenticated: Bool = true
    ) -> MealRepository {
        MealRepository(
            localDataSource: local, remoteApi: FakeOpenFoodFacts(), remote: remote,
            session: StubSession(authenticated: authenticated)
        )
    }

    /// Sesión propia del test. Antes se cambiaba `AuthSession.shared`, que es un
    /// singleton compartido por toda la suite: con los tests corriendo en PARALELO,
    /// un test que la cambiaba hacía fallar a otro que se ejecutaba a la vez, y el
    /// fallo salía en la clase equivocada.
    private struct StubSession: AuthStateProviding {
        let authenticated: Bool
        var isAuthenticated: Bool { get async { authenticated } }
    }

    // MARK: - El bug

    func testLoggedInFavoritesIncludeGuestOnesInsteadOfReplacingThem() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena de invitado").toDTO()]
        let remote = FakeRemote()
        remote.favorites = [dto(UUID(), "Pollo de la cuenta")]
        let repository = makeRepository(local: local, remote: remote)

        let result = try await repository.getFavorites()
        XCTAssertEqual(
            Set(result.map(\.name)), ["Pollo de la cuenta", "Avena de invitado"],
            "los de invitado deben convivir con los de la cuenta"
        )
    }

    func testMergeDoesNotDuplicateTheSameFoodPresentOnBothSides() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena", barcode: "123").toDTO()]
        let remote = FakeRemote()
        // Mismo alimento ya subido: otro UUID, mismo código de barras.
        remote.favorites = [dto(UUID(), "Avena", barcode: "123")]
        let repository = makeRepository(local: local, remote: remote)

        let result = try await repository.getFavorites()
        XCTAssertEqual(result.count, 1, "dedup por identityKey, no por id")
    }

    func testGuestFavoritesAreUploadedOnSync() async throws {
        let local = FakeLocal()
        local.favorites = [
            food("Avena", barcode: "123").toDTO(),
            food("Pollo").toDTO()
        ]
        let remote = FakeRemote()
        let repository = makeRepository(local: local, remote: remote)

        let synced = try await repository.syncLocalToRemote()
        XCTAssertEqual(synced, 2, "los dos favoritos locales deben subirse")
        XCTAssertEqual(remote.addedFavoriteIds.count, 2)
        XCTAssertEqual(Set(remote.createdFoods.map(\.name)), ["Avena", "Pollo"])
    }

    /// El backend genera el id al crear el alimento; usar el local hacía que
    /// `POST /v1/foods/{id}/favorite` apuntara a un alimento inexistente.
    func testFavoriteUsesTheServerAssignedIdNotTheLocalOne() async throws {
        let local = FakeLocal()
        let localFood = food("Avena", barcode: "123")
        local.favorites = [localFood.toDTO()]
        let serverId = UUID()
        let remote = FakeRemote()
        remote.idsToAssign = [serverId]
        let repository = makeRepository(local: local, remote: remote)

        _ = try await repository.syncLocalToRemote()
        XCTAssertEqual(remote.addedFavoriteIds, [serverId])
        XCTAssertNotEqual(
            remote.addedFavoriteIds.first, localFood.id,
            "el id local no existe en el servidor"
        )
    }

    /// Si el alimento ya está en el servidor (mismo barcode) no se vuelve a crear.
    func testExistingServerFoodIsReusedInsteadOfDuplicated() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena", barcode: "123").toDTO()]
        let existingId = UUID()
        let remote = FakeRemote()
        remote.foodsByBarcode = ["123": dto(existingId, "Avena", barcode: "123")]
        let repository = makeRepository(local: local, remote: remote)

        _ = try await repository.syncLocalToRemote()
        XCTAssertEqual(remote.addedFavoriteIds, [existingId])
        XCTAssertTrue(remote.createdFoods.isEmpty, "no debe duplicar el alimento")
    }

    func testPendingCountSeesGuestFavorites() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena").toDTO(), food("Pollo").toDTO()]
        let remote = FakeRemote()
        remote.favorites = [dto(UUID(), "Avena")]   // uno ya está en la cuenta
        let repository = makeRepository(local: local, remote: remote)

        let pending = try await repository.pendingSyncCount()
        XCTAssertEqual(pending, 1, "solo el que falta en la cuenta")
    }

    /// Con la mezcla en la lectura, quitar un favorito local tenía que borrarlo
    /// también en local o la siguiente lectura lo resucitaba.
    func testRemovingALocalOnlyFavoriteDoesNotResurrect() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena").toDTO(), food("Pollo").toDTO()]
        let remote = FakeRemote()
        let repository = makeRepository(local: local, remote: remote)

        let remaining = try await repository.getFavorites().filter { $0.name != "Avena" }
        try await repository.saveFavorites(remaining)

        let after = try await repository.getFavorites()
        XCTAssertEqual(after.map(\.name), ["Pollo"], "'Avena' no debe reaparecer")
    }

    func testGuestModeStillReadsAndWritesOnlyLocal() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena").toDTO()]
        let remote = FakeRemote()
        remote.favorites = [dto(UUID(), "No debería verse")]
        let repository = makeRepository(local: local, remote: remote, authenticated: false)

        let result = try await repository.getFavorites()
        XCTAssertEqual(result.map(\.name), ["Avena"])
        XCTAssertTrue(remote.addedFavoriteIds.isEmpty)
    }
}

/// Las comidas (desayuno/comida/cena) registradas como invitado tenían el mismo
/// problema que los favoritos, y además la subida a la cuenta es MANUAL, así que
/// quedaban invisibles hasta que el usuario pulsaba Sincronizar.
extension MealFavoritesSyncTests {

    private func meal(_ id: UUID, _ type: MealType, hour: Int) -> Meal {
        Meal(
            id: id,
            type: type,
            timestamp: Calendar.current.date(
                bySettingHour: hour, minute: 0, second: 0, of: Date()
            ) ?? Date(),
            items: []
        )
    }

    func testGuestMealsRemainVisibleAfterLogin() async throws {
        let local = FakeLocal()
        let breakfast = meal(UUID(), .breakfast, hour: 9)
        let dinner = meal(UUID(), .dinner, hour: 21)
        local.meals = [breakfast.toDTO(), dinner.toDTO()]

        let remote = FakeRemote()
        let repository = makeRepository(local: local, remote: remote)

        let result = try await repository.getMeals(for: Date())
        XCTAssertEqual(
            result.map(\.id), [breakfast.id, dinner.id],
            "las comidas locales siguen visibles, y ordenadas por hora"
        )
    }

    // MARK: - "Mis comidas" (recetas guardadas)

    private func myMeal(_ id: UUID, _ name: String) -> MyMeal {
        MyMeal(id: id, name: name, items: [], createdAt: Date())
    }

    /// El bug que se reportó: con sesión iniciada, "Mis comidas" leía SOLO del
    /// servidor, así que las recetas creadas como invitado desaparecían — seguían en
    /// el dispositivo, pero nadie las leía. Al cerrar sesión volvían a aparecer, que
    /// es exactamente el síntoma con el que se detectó.
    func testGuestRecipesRemainVisibleAfterLogin() async throws {
        let local = FakeLocal()
        local.myMeals = [myMeal(UUID(), "Tortilla de invitado").toDTO()]
        let remote = FakeRemote()
        remote.myMeals = [MyMealApiDTO(id: UUID(), name: "Ensalada de la cuenta", items: [])]
        let repository = makeRepository(local: local, remote: remote)

        let result = try await repository.getMyMeals()
        XCTAssertEqual(
            Set(result.map(\.name)), ["Ensalada de la cuenta", "Tortilla de invitado"],
            "las recetas de invitado conviven con las de la cuenta"
        )
    }

    func testASyncedRecipeIsNotDuplicated() async throws {
        let shared = UUID()
        let local = FakeLocal()
        local.myMeals = [myMeal(shared, "Tortilla").toDTO()]
        let remote = FakeRemote()
        // Ya subida: `createMyMeal` manda el id local y el backend lo conserva.
        remote.myMeals = [MyMealApiDTO(id: shared, name: "Tortilla", items: [])]
        let repository = makeRepository(local: local, remote: remote)

        let result = try await repository.getMyMeals()
        XCTAssertEqual(result.count, 1, "dedup por id")
    }

    func testServerFailureDoesNotHideLocalRecipes() async throws {
        let local = FakeLocal()
        local.myMeals = [myMeal(UUID(), "Tortilla de invitado").toDTO()]
        let remote = FakeRemote()
        remote.isOffline = true
        let repository = makeRepository(local: local, remote: remote)

        let result = try await repository.getMyMeals()
        XCTAssertEqual(result.map(\.name), ["Tortilla de invitado"], "degrada a local")
    }

    /// Con la fusión en la lectura, borrar una receta que solo existía en local no la
    /// borraba de ninguna parte (el servidor no la tiene) y reaparecía. Mismo motivo
    /// por el que `saveFavorites` reescribe la copia local estando autenticado.
    func testDeletingALocalOnlyRecipeWhileLoggedInDoesNotResurrect() async throws {
        let local = FakeLocal()
        let guestRecipe = myMeal(UUID(), "Tortilla de invitado")
        local.myMeals = [guestRecipe.toDTO()]
        let repository = makeRepository(local: local, remote: FakeRemote())

        // El usuario la quita: se guarda la lista sin ella.
        try await repository.saveMyMeals([])

        let result = try await repository.getMyMeals()
        XCTAssertTrue(result.isEmpty, "no puede volver en la siguiente lectura")
        XCTAssertTrue(local.myMeals.isEmpty, "y se ha ido del dispositivo")
    }

    // MARK: - La comida se guarda siempre en el dispositivo

    /// La otra mitad del bug reportado: lo registrado con sesión iniciada se escribía
    /// SOLO en el servidor, así que al cerrar sesión desaparecía todo (el dispositivo
    /// no tenía copia).
    func testAMealSavedWhileLoggedInIsAlsoKeptOnTheDevice() async throws {
        let local = FakeLocal()
        let remote = FakeRemote()
        let repository = makeRepository(local: local, remote: remote)

        let lunch = meal(UUID(), .lunch, hour: 14)
        try await repository.saveMeal(lunch)

        XCTAssertEqual(remote.createdMeals.map(\.id), [lunch.id], "llega al servidor")
        XCTAssertEqual(local.meals.map(\.id), [lunch.id], "y se queda en el dispositivo")
    }

    /// Y si el servidor no está, la comida no se pierde: queda en el dispositivo y la
    /// sincronización la sube después.
    func testAMealSurvivesAServerFailureWhileLoggedIn() async throws {
        let local = FakeLocal()
        let remote = FakeRemote()
        remote.isOffline = true
        let repository = makeRepository(local: local, remote: remote)

        let lunch = meal(UUID(), .lunch, hour: 14)
        try await repository.saveMeal(lunch)

        XCTAssertEqual(local.meals.map(\.id), [lunch.id], "guardada en el dispositivo")
        let visible = try await repository.getMeals(for: Date())
        XCTAssertEqual(visible.map(\.id), [lunch.id], "y visible en la pantalla")
    }

    func testSyncedMealIsNotDuplicatedAfterUpload() async throws {
        let shared = UUID()
        let local = FakeLocal()
        local.meals = [meal(shared, .lunch, hour: 14).toDTO()]

        let remote = FakeRemote()
        // Ya subida: el backend conserva el id local que le manda `createMeal`.
        let lunch = meal(shared, .lunch, hour: 14)
        remote.meals = [
            MealApiDTO(
                id: lunch.id, type: lunch.type.rawValue,
                timestamp: lunch.timestamp, items: [], myMealName: nil
            )
        ]
        let repository = makeRepository(local: local, remote: remote)

        let result = try await repository.getMeals(for: Date())
        XCTAssertEqual(result.count, 1, "dedup por id, no se duplica")
    }
}

/// Un fallo del servidor no debe esconder lo que solo existe en el dispositivo:
/// los llamantes que usan `try?` (el contexto de la IA) se quedaban sin nada.
extension MealFavoritesSyncTests {

    private final class FailingRemote: MealRemoteDataSourceProtocol {
        enum Boom: Error { case network }

        func createMeal(_ meal: Meal) async throws -> MealApiDTO { throw Boom.network }
        func listMeals(for date: Date) async throws -> [MealApiDTO] { throw Boom.network }
        func listMeals(from start: Date, to end: Date) async throws -> [MealApiDTO] { throw Boom.network }
        func deleteMeal(id: UUID) async throws { throw Boom.network }
        func foodByBarcode(_ barcode: String) async throws -> FoodApiDTO? { throw Boom.network }
        func listFavorites() async throws -> [FoodApiDTO] { throw Boom.network }
        func addFavorite(foodId: UUID) async throws { throw Boom.network }
        func removeFavorite(foodId: UUID) async throws { throw Boom.network }
        func createCustomFood(_ food: FoodItem) async throws -> FoodApiDTO { throw Boom.network }
        func listMyMeals() async throws -> [MyMealApiDTO] { throw Boom.network }
        func createMyMeal(_ myMeal: MyMeal) async throws -> MyMealApiDTO { throw Boom.network }
        func deleteMyMeal(id: UUID) async throws { throw Boom.network }
    }

    func testServerFailureDegradesToLocalMealsInsteadOfLosingTheDay() async throws {
        let local = FakeLocal()
        let breakfast = meal(UUID(), .breakfast, hour: 9)
        local.meals = [breakfast.toDTO()]
        let repository = MealRepository(
            localDataSource: local, remoteApi: FakeOpenFoodFacts(), remote: FailingRemote()
        )

        let result = try await repository.getMeals(for: Date())
        XCTAssertEqual(result.map(\.id), [breakfast.id], "se ve lo local aunque falle el servidor")

        let range = try await repository.getMeals(
            from: Date().addingTimeInterval(-86_400), to: Date()
        )
        XCTAssertEqual(range.count, 1)
    }

    func testServerFailureDegradesToLocalFavorites() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena").toDTO()]
        let repository = MealRepository(
            localDataSource: local, remoteApi: FakeOpenFoodFacts(), remote: FailingRemote()
        )

        let result = try await repository.getFavorites()
        XCTAssertEqual(result.map(\.name), ["Avena"])
    }
}
