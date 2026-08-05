import XCTest
@testable import microworkout

/// Los alimentos añadidos como invitado desaparecían de "Favoritos" al iniciar
/// sesión: la lectura pasaba a ser solo-servidor y la sincronización de login no
/// los subía. Estos tests fijan que convivan.
///
/// `MealRepository` decide por `AuthSession.shared`, que es un singleton
/// `@MainActor`, así que los tests con sesión se ejecutan poniendo la sesión en el
/// estado que toca y restaurándola al final.
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

        func createMeal(_ meal: Meal) async throws -> MealApiDTO { throw Fake.unused }
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

        func listMyMeals() async throws -> [MyMealApiDTO] { [] }
        func createMyMeal(_ myMeal: MyMeal) async throws -> MyMealApiDTO { throw Fake.unused }
        func deleteMyMeal(id: UUID) async throws {}
    }

    private enum Fake: Error { case unused, unknownFood }

    private final class FakeLocal: MealDataSourceProtocol {
        var favorites: [FoodItemDTO] = []
        var myMeals: [MyMealDTO] = []
        var meals: [MealDTO] = []
        var customFoods: [String: FoodItemDTO] = [:]

        func saveMeal(_ meal: MealDTO) async throws { meals.append(meal) }
        func getMeals(for date: Date) async throws -> [MealDTO] { meals }
        func getMeals(from startDate: Date, to endDate: Date) async throws -> [MealDTO] { meals }
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
        local: FakeLocal, remote: FakeRemote
    ) -> MealRepository {
        MealRepository(localDataSource: local, remoteApi: FakeOpenFoodFacts(), remote: remote)
    }

    /// Ejecuta el bloque con la sesión autenticada y restaura el estado al salir.
    @MainActor
    private func withAuthenticatedSession(_ body: () async throws -> Void) async rethrows {
        let previous = AuthSession.shared.state
        AuthSession.shared.setAuthenticated(
            AuthenticatedUser(id: 1, email: "a@b.c", fullname: "Test", phone: nil)
        )
        defer {
            if case .authenticated(let user) = previous {
                AuthSession.shared.setAuthenticated(user)
            } else {
                AuthSession.shared.setGuest()
            }
        }
        try await body()
    }

    // MARK: - El bug

    func testLoggedInFavoritesIncludeGuestOnesInsteadOfReplacingThem() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena de invitado").toDTO()]
        let remote = FakeRemote()
        remote.favorites = [dto(UUID(), "Pollo de la cuenta")]
        let repository = makeRepository(local: local, remote: remote)

        try await withAuthenticatedSession {
            let result = try await repository.getFavorites()
            XCTAssertEqual(
                Set(result.map(\.name)), ["Pollo de la cuenta", "Avena de invitado"],
                "los de invitado deben convivir con los de la cuenta"
            )
        }
    }

    func testMergeDoesNotDuplicateTheSameFoodPresentOnBothSides() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena", barcode: "123").toDTO()]
        let remote = FakeRemote()
        // Mismo alimento ya subido: otro UUID, mismo código de barras.
        remote.favorites = [dto(UUID(), "Avena", barcode: "123")]
        let repository = makeRepository(local: local, remote: remote)

        try await withAuthenticatedSession {
            let result = try await repository.getFavorites()
            XCTAssertEqual(result.count, 1, "dedup por identityKey, no por id")
        }
    }

    func testGuestFavoritesAreUploadedOnSync() async throws {
        let local = FakeLocal()
        local.favorites = [
            food("Avena", barcode: "123").toDTO(),
            food("Pollo").toDTO()
        ]
        let remote = FakeRemote()
        let repository = makeRepository(local: local, remote: remote)

        try await withAuthenticatedSession {
            let synced = try await repository.syncLocalToRemote()
            XCTAssertEqual(synced, 2, "los dos favoritos locales deben subirse")
            XCTAssertEqual(remote.addedFavoriteIds.count, 2)
            XCTAssertEqual(Set(remote.createdFoods.map(\.name)), ["Avena", "Pollo"])
        }
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

        try await withAuthenticatedSession {
            _ = try await repository.syncLocalToRemote()
            XCTAssertEqual(remote.addedFavoriteIds, [serverId])
            XCTAssertNotEqual(
                remote.addedFavoriteIds.first, localFood.id,
                "el id local no existe en el servidor"
            )
        }
    }

    /// Si el alimento ya está en el servidor (mismo barcode) no se vuelve a crear.
    func testExistingServerFoodIsReusedInsteadOfDuplicated() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena", barcode: "123").toDTO()]
        let existingId = UUID()
        let remote = FakeRemote()
        remote.foodsByBarcode = ["123": dto(existingId, "Avena", barcode: "123")]
        let repository = makeRepository(local: local, remote: remote)

        try await withAuthenticatedSession {
            _ = try await repository.syncLocalToRemote()
            XCTAssertEqual(remote.addedFavoriteIds, [existingId])
            XCTAssertTrue(remote.createdFoods.isEmpty, "no debe duplicar el alimento")
        }
    }

    func testPendingCountSeesGuestFavorites() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena").toDTO(), food("Pollo").toDTO()]
        let remote = FakeRemote()
        remote.favorites = [dto(UUID(), "Avena")]   // uno ya está en la cuenta
        let repository = makeRepository(local: local, remote: remote)

        try await withAuthenticatedSession {
            let pending = try await repository.pendingSyncCount()
            XCTAssertEqual(pending, 1, "solo el que falta en la cuenta")
        }
    }

    /// Con la mezcla en la lectura, quitar un favorito local tenía que borrarlo
    /// también en local o la siguiente lectura lo resucitaba.
    func testRemovingALocalOnlyFavoriteDoesNotResurrect() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena").toDTO(), food("Pollo").toDTO()]
        let remote = FakeRemote()
        let repository = makeRepository(local: local, remote: remote)

        try await withAuthenticatedSession {
            let remaining = try await repository.getFavorites().filter { $0.name != "Avena" }
            try await repository.saveFavorites(remaining)

            let after = try await repository.getFavorites()
            XCTAssertEqual(after.map(\.name), ["Pollo"], "'Avena' no debe reaparecer")
        }
    }

    func testGuestModeStillReadsAndWritesOnlyLocal() async throws {
        let local = FakeLocal()
        local.favorites = [food("Avena").toDTO()]
        let remote = FakeRemote()
        remote.favorites = [dto(UUID(), "No debería verse")]
        let repository = makeRepository(local: local, remote: remote)

        await MainActor.run { AuthSession.shared.setGuest() }
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

        try await withAuthenticatedSession {
            let result = try await repository.getMeals(for: Date())
            XCTAssertEqual(
                result.map(\.id), [breakfast.id, dinner.id],
                "las comidas locales siguen visibles, y ordenadas por hora"
            )
        }
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

        try await withAuthenticatedSession {
            let result = try await repository.getMeals(for: Date())
            XCTAssertEqual(result.count, 1, "dedup por id, no se duplica")
        }
    }
}
