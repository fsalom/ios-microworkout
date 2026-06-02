import Foundation

/// Dispatch igual al de Workouts/UserProfile/WorkoutLog:
/// invitado → `UserDefaults` (todo local, offline-first);
/// autenticado → backend `/v1/meals`, `/v1/foods/*` y `/v1/my-meals`.
///
/// OpenFoodFacts y los `customFoods` se mantienen siempre locales: la búsqueda
/// pública es independiente de la cuenta, y el caché de códigos de barras es
/// un fallback offline para escaneos.
class MealRepository: MealRepositoryProtocol {
    private let localDataSource: MealDataSourceProtocol
    private let remoteApi: OpenFoodFactsApiProtocol
    private let remote: MealRemoteDataSourceProtocol

    init(
        localDataSource: MealDataSourceProtocol,
        remoteApi: OpenFoodFactsApiProtocol,
        remote: MealRemoteDataSourceProtocol
    ) {
        self.localDataSource = localDataSource
        self.remoteApi = remoteApi
        self.remote = remote
    }

    private func isAuthenticated() async -> Bool {
        await MainActor.run { AuthSession.shared.state.isAuthenticated }
    }

    // MARK: Meals

    func saveMeal(_ meal: Meal) async throws {
        if await isAuthenticated() {
            _ = try await remote.createMeal(meal)
            return
        }
        try await localDataSource.saveMeal(meal.toDTO())
    }

    func getMeals(for date: Date) async throws -> [Meal] {
        if await isAuthenticated() {
            return try await remote.listMeals(for: date).map { $0.toDomain() }
        }
        return try await localDataSource.getMeals(for: date).map { $0.toDomain() }
    }

    func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] {
        if await isAuthenticated() {
            return try await remote.listMeals(from: startDate, to: endDate).map { $0.toDomain() }
        }
        return try await localDataSource.getMeals(from: startDate, to: endDate).map { $0.toDomain() }
    }

    func deleteMeal(_ mealId: UUID) async throws {
        if await isAuthenticated() {
            try await remote.deleteMeal(id: mealId)
            return
        }
        try await localDataSource.deleteMeal(mealId)
    }

    // MARK: Remote (OpenFoodFacts) — público, no depende de auth

    func fetchFoodInfo(barcode: String) async throws -> FoodItem? {
        do {
            guard let productDTO = try await remoteApi.fetchProduct(barcode: barcode) else {
                return nil
            }
            return productDTO.toDomain(barcode: barcode)
        } catch {
            throw DomainError.map(error)
        }
    }

    func searchFoods(query: String) async throws -> [FoodItem] {
        do {
            let products = try await remoteApi.searchProducts(query: query, page: 1, pageSize: 25)
            return products.map { $0.toDomain() }
        } catch {
            throw DomainError.map(error)
        }
    }

    // MARK: Favorites

    func getFavorites() async throws -> [FoodItem] {
        if await isAuthenticated() {
            return try await remote.listFavorites().map { $0.toDomain() }
        }
        return localDataSource.getFavorites().map { $0.toDomain() }
    }

    /// Diffea contra el servidor cuando el usuario está autenticado para emitir
    /// add/remove explícitos — el backend solo expone POST/DELETE por food_id.
    /// En modo invitado escribe la lista entera en UserDefaults igual que antes.
    func saveFavorites(_ favorites: [FoodItem]) async throws {
        if await isAuthenticated() {
            let currentDTOs = try await remote.listFavorites()
            let currentIds = Set(currentDTOs.compactMap { $0.id })
            let newIds = Set(favorites.map { $0.id })

            for id in newIds.subtracting(currentIds) {
                try await ensureFoodOnServer(id: id, in: favorites)
                try await remote.addFavorite(foodId: id)
            }
            for id in currentIds.subtracting(newIds) {
                try await remote.removeFavorite(foodId: id)
            }
            return
        }
        localDataSource.saveFavorites(favorites.map { $0.toDTO() })
    }

    /// El endpoint `POST /v1/foods/{id}/favorite` requiere que el food ya exista
    /// en `/v1/foods/custom`. Para favoritos creados desde OpenFoodFacts (sin
    /// existir aún en backend) los registramos primero.
    private func ensureFoodOnServer(id: UUID, in foods: [FoodItem]) async throws {
        guard let food = foods.first(where: { $0.id == id }) else { return }
        // Best-effort: si ya existe (mismo barcode), el backend devolverá un 4xx
        // por unique constraint; ignoramos para que el flujo no se rompa.
        do {
            _ = try await remote.createCustomFood(food)
        } catch {
            // Silenciar — el favorito puede provenir de un Food preexistente.
        }
    }

    // MARK: My meals (recipes)

    func getMyMeals() async throws -> [MyMeal] {
        if await isAuthenticated() {
            return try await remote.listMyMeals().map { $0.toDomain() }
        }
        return localDataSource.getMyMeals().map { $0.toDomain() }
    }

    /// Diffea contra el servidor: crea los nuevos, borra los que ya no están.
    /// El backend no expone update; para editar = borrar + crear.
    func saveMyMeals(_ meals: [MyMeal]) async throws {
        if await isAuthenticated() {
            let currentDTOs = try await remote.listMyMeals()
            let currentIds = Set(currentDTOs.map { $0.id })
            let newIds = Set(meals.map { $0.id })

            for id in currentIds.subtracting(newIds) {
                try await remote.deleteMyMeal(id: id)
            }
            for meal in meals where !currentIds.contains(meal.id) {
                _ = try await remote.createMyMeal(meal)
            }
            return
        }
        localDataSource.saveMyMeals(meals.map { $0.toDTO() })
    }

    // MARK: Custom foods — siempre local (caché de fallback para escáner)

    func getCustomFoods() -> [String: FoodItem] {
        localDataSource.getCustomFoods().mapValues { $0.toDomain() }
    }

    func saveCustomFoods(_ foods: [String: FoodItem]) {
        localDataSource.saveCustomFoods(foods.mapValues { $0.toDTO() })
    }
}

fileprivate extension OpenFoodFactsProductDTO {
    func toDomain(barcode: String? = nil) -> FoodItem {
        FoodItem(
            id: UUID(),
            name: displayName,
            barcode: barcode ?? code,
            nutritionPer100g: NutritionInfo(
                calories: nutriments?.energyKcal100g ?? 0,
                carbohydrates: nutriments?.carbohydrates100g ?? 0,
                proteins: nutriments?.proteins100g ?? 0,
                fats: nutriments?.fat100g ?? 0,
                fiber: nutriments?.fiber100g
            ),
            quantity: 100,
            servingSize: nil,
            imageUrl: thumbnailUrl ?? imageUrl
        )
    }
}
