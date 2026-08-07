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

    private let session: AuthStateProviding

    init(
        localDataSource: MealDataSourceProtocol,
        remoteApi: OpenFoodFactsApiProtocol,
        remote: MealRemoteDataSourceProtocol,
        session: AuthStateProviding = SharedAuthState()
    ) {
        self.localDataSource = localDataSource
        self.remoteApi = remoteApi
        self.remote = remote
        self.session = session
    }

    private func isAuthenticated() async -> Bool {
        await session.isAuthenticated
    }

    // MARK: Meals

    func saveMeal(_ meal: Meal) async throws {
        if await isAuthenticated() {
            _ = try await remote.createMeal(meal)
            return
        }
        try await localDataSource.saveMeal(meal.toDTO())
    }

    /// Modelo espejo: cuenta las comidas y "mis comidas" locales cuyo id no está
    /// aún en la cuenta. No modifica nada local.
    func pendingSyncCount() async throws -> Int {
        var pending = 0
        let localMeals = try await localDataSource.getAllMeals()
        if !localMeals.isEmpty {
            let remoteIds = try await remoteMealIds(covering: localMeals)
            pending += localMeals.filter { !remoteIds.contains($0.id) }.count
        }
        let localMyMeals = localDataSource.getMyMeals()
        if !localMyMeals.isEmpty {
            let remoteMyMealIds = Set(try await remote.listMyMeals().map { $0.id })
            pending += localMyMeals.filter { !remoteMyMealIds.contains($0.id) }.count
        }
        pending += try await unsyncedFavorites().count
        return pending
    }

    /// Favoritos locales que aún no están en la cuenta. Se comparan por
    /// `identityKey` y no por `id`: el mismo alimento tiene UUID distinto en local
    /// y en servidor.
    private func unsyncedFavorites() async throws -> [FoodItem] {
        let local = localDataSource.getFavorites().map { $0.toDomain() }
        guard !local.isEmpty else { return [] }
        let syncedKeys = Set(try await remote.listFavorites().map { $0.toDomain().identityKey })
        return local.filter { !syncedKeys.contains($0.identityKey) }
    }

    /// Sube las comidas y recetas locales que aún no estén en la cuenta (por id).
    /// Nunca borra la copia local — el dispositivo conserva el respaldo.
    func syncLocalToRemote() async throws -> Int {
        var count = 0
        let localMeals = try await localDataSource.getAllMeals()
        if !localMeals.isEmpty {
            let remoteIds = try await remoteMealIds(covering: localMeals)
            for dto in localMeals where !remoteIds.contains(dto.id) {
                _ = try await remote.createMeal(dto.toDomain()); count += 1
            }
        }
        let localMyMeals = localDataSource.getMyMeals()
        if !localMyMeals.isEmpty {
            let remoteMyMealIds = Set(try await remote.listMyMeals().map { $0.id })
            for dto in localMyMeals where !remoteMyMealIds.contains(dto.id) {
                _ = try await remote.createMyMeal(dto.toDomain()); count += 1
            }
        }
        // Los favoritos también se suben: sin esto, los alimentos añadidos como
        // invitado se quedaban para siempre fuera de la cuenta (visibles solo por
        // la mezcla de lectura, y perdidos al cambiar de dispositivo).
        for food in try await unsyncedFavorites() {
            do {
                try await remote.addFavorite(foodId: try await serverFoodId(for: food))
                count += 1
            } catch {
                // Un favorito que el backend rechaza no debe abortar el resto de la
                // sincronización: se queda como pendiente y se reintenta al siguiente login.
                continue
            }
        }
        return count
    }

    /// Ids de comidas ya en la cuenta que cubren el rango de fechas de las
    /// comidas locales (el backend lista comidas por rango de fechas).
    private func remoteMealIds(covering localMeals: [MealDTO]) async throws -> Set<UUID> {
        let timestamps = localMeals.map { $0.timestamp }
        guard let from = timestamps.min(), let to = timestamps.max() else { return [] }
        let remoteMeals = try await remote.listMeals(from: from, to: to)
        return Set(remoteMeals.map { $0.id })
    }

    /// Cuenta + comidas locales que aún no están en ella.
    ///
    /// La subida a la cuenta es manual (Perfil → Sincronización), así que sin esta
    /// mezcla las comidas registradas como invitado quedaban invisibles al iniciar
    /// sesión hasta que el usuario pulsara el botón. Aquí el dedup **sí** puede ser
    /// por `id`: `createMeal` manda el id local, así que una comida subida conserva
    /// el mismo identificador en las dos partes.
    func getMeals(for date: Date) async throws -> [Meal] {
        let local = try await localDataSource.getMeals(for: date).map { $0.toDomain() }
        guard await isAuthenticated() else { return local }

        // Si el servidor falla se degrada a local en vez de propagar: lo local es la
        // única copia de lo registrado como invitado, y perderlo de vista por un
        // fallo de red es peor que mostrar solo una parte. Los llamantes que usan
        // `try?` (como el contexto de la IA) se quedaban sin NADA del día.
        let synced = (try? await remote.listMeals(for: date))?.map { $0.toDomain() } ?? []
        return Self.merge(synced: synced, local: local)
    }

    func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] {
        let local = try await localDataSource
            .getMeals(from: startDate, to: endDate).map { $0.toDomain() }
        guard await isAuthenticated() else { return local }

        let synced = (try? await remote.listMeals(from: startDate, to: endDate))?
            .map { $0.toDomain() } ?? []
        return Self.merge(synced: synced, local: local)
    }

    /// Se ordena por hora al mezclar: los consumidores que agrupan por tipo de
    /// comida no dependían del orden de llegada, pero concatenar dos fuentes sin
    /// ordenar dejaría el día descolocado.
    private static func merge(synced: [Meal], local: [Meal]) -> [Meal] {
        let syncedIds = Set(synced.map { $0.id })
        return (synced + local.filter { !syncedIds.contains($0.id) })
            .sorted { $0.timestamp < $1.timestamp }
    }

    func deleteMeal(_ mealId: UUID) async throws {
        if await isAuthenticated() {
            try await remote.deleteMeal(id: mealId)
            // Borrar también la copia local: si se queda, la siguiente
            // sincronización la ve como "pendiente" (no está en el servidor) y la
            // vuelve a subir, resucitando una comida que el usuario borró.
            try? await localDataSource.deleteMeal(mealId)
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

    /// Mismo criterio que `ExerciseRepository`: al estar autenticado se muestran los
    /// de la cuenta MÁS los locales que aún no están en ella, en vez de solo los del
    /// servidor. Si no, los alimentos añadidos como invitado desaparecen de la
    /// pestaña "Favoritos" al iniciar sesión — no se borran, pero nadie los lee.
    func getFavorites() async throws -> [FoodItem] {
        let local = localDataSource.getFavorites().map { $0.toDomain() }
        guard await isAuthenticated() else { return local }

        // Igual que con las comidas: un fallo del servidor no debe esconder los
        // favoritos que solo existen en el dispositivo.
        let synced = (try? await remote.listFavorites())?.map { $0.toDomain() } ?? []
        let syncedKeys = Set(synced.map { $0.identityKey })
        return synced + local.filter { !syncedKeys.contains($0.identityKey) }
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
                guard let food = favorites.first(where: { $0.id == id }) else { continue }
                try await remote.addFavorite(foodId: try await serverFoodId(for: food))
            }
            for id in currentIds.subtracting(newIds) {
                try await remote.removeFavorite(foodId: id)
            }
            // La copia local se reescribe también estando autenticado. Si no, al
            // quitar un favorito que solo existía en local no se borraría de
            // ninguna parte (el servidor no lo tiene) y la mezcla de `getFavorites`
            // lo resucitaría en la siguiente lectura.
            localDataSource.saveFavorites(favorites.map { $0.toDTO() })
            return
        }
        localDataSource.saveFavorites(favorites.map { $0.toDTO() })
    }

    /// Id que el alimento tiene **en el servidor**, creándolo allí si no existe.
    ///
    /// `POST /v1/foods/custom` no acepta id: la BD genera el suyo y lo devuelve. El
    /// id local por tanto no vale para `POST /v1/foods/{id}/favorite`, que apuntaría
    /// a un alimento inexistente — por eso marcar como favorito un alimento de
    /// OpenFoodFacts fallaba en silencio estando logueado.
    ///
    /// Se busca primero por código de barras para no crear duplicados en cada
    /// intento; sin barcode no hay forma de reconocerlo y se crea.
    private func serverFoodId(for food: FoodItem) async throws -> UUID {
        if let barcode = food.barcode, !barcode.isEmpty,
           let existing = try? await remote.foodByBarcode(barcode),
           let existingId = existing.id {
            return existingId
        }
        let created = try await remote.createCustomFood(food)
        guard let createdId = created.id else {
            throw DomainError.decoding(underlying: URLError(.cannotParseResponse))
        }
        return createdId
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
