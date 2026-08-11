import XCTest
@testable import microworkout

/// Home sumaba en "calorías de hoy" comidas que no eran de hoy.
///
/// Causa: la fecha de la consulta al servidor se formateaba en UTC. Con cualquier
/// zona por delante de Greenwich —España todo el año— la medianoche local cae en el
/// día UTC ANTERIOR, así que la app pedía las comidas de AYER y el repositorio las
/// metía sin filtrar en la lista de hoy.
final class MealDayBoundaryTests: XCTestCase {

    // MARK: - La fecha que se le pide al servidor

    /// Reproduce el formateador tal y como estaba (UTC) y como está ahora (local),
    /// sobre el mismo instante que usa `getMealsForToday`: la medianoche local.
    private func dayString(timeZone: TimeZone, for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// El día local y el día UTC de la medianoche local NO son el mismo con offset
    /// positivo. Este test documenta el error que se cometía.
    func testLocalMidnightFallsOnThePreviousUTCDay() throws {
        var madrid = Calendar(identifier: .gregorian)
        madrid.timeZone = TimeZone(identifier: "Europe/Madrid")!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = madrid.timeZone
        let noon = formatter.date(from: "2026-08-11 12:00")!

        // Lo que hace `getMealsForToday()`.
        let startOfDay = madrid.startOfDay(for: noon)

        XCTAssertEqual(
            dayString(timeZone: madrid.timeZone, for: startOfDay), "2026-08-11",
            "en la zona del usuario es el día 11"
        )
        XCTAssertEqual(
            dayString(timeZone: TimeZone(secondsFromGMT: 0)!, for: startOfDay), "2026-08-10",
            "pero en UTC es el 10: por esto se pedían las comidas de ayer"
        )
    }

    /// Y la pieza real ya no formatea en UTC. Es una sola función y la usan las tres
    /// consultas de comidas, así que aquí no puede volver a colarse un GMT suelto.
    func testTheDayAskedForIsTheUsersOwnDay() throws {
        var madrid = Calendar(identifier: .gregorian)
        madrid.timeZone = TimeZone(identifier: "Europe/Madrid")!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = madrid.timeZone
        let startOfDay = madrid.startOfDay(for: formatter.date(from: "2026-08-11 12:00")!)

        XCTAssertEqual(
            MealTime.daySlug(startOfDay, calendar: madrid), "2026-08-11",
            "el día del usuario, no el UTC de su medianoche"
        )
    }

    /// Y en invierno, con offset +01:00, exactamente igual.
    func testTheDayIsCorrectInWinterToo() throws {
        var madrid = Calendar(identifier: .gregorian)
        madrid.timeZone = TimeZone(identifier: "Europe/Madrid")!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = madrid.timeZone
        let startOfDay = madrid.startOfDay(for: formatter.date(from: "2026-01-15 12:00")!)

        XCTAssertEqual(MealTime.daySlug(startOfDay, calendar: madrid), "2026-01-15")
    }

    // MARK: - El repositorio no se fía de la respuesta

    /// Cinturón: aunque la consulta ya vaya bien, si el servidor contesta con un día
    /// distinto al pedido esas comidas no pueden entrar en el total.
    func testMealsFromAnotherDayInTheServerResponseAreNotCounted() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let local = FakeLocal()
        let remote = FakeRemote()
        // El servidor contesta con una de hoy y otra de ayer.
        remote.mealsToReturn = [
            apiMeal(timestamp: calendar.date(byAdding: .hour, value: 14, to: today)!),
            apiMeal(timestamp: calendar.date(byAdding: .hour, value: 21, to: yesterday)!),
        ]
        let repository = MealRepository(
            localDataSource: local, remoteApi: FakeOpenFoodFacts(), remote: remote,
            session: StubSession(authenticated: true)
        )

        let result = try await repository.getMeals(for: today)
        XCTAssertEqual(result.count, 1, "la de ayer se descarta")
        XCTAssertTrue(
            result.allSatisfy { calendar.isDate($0.timestamp, inSameDayAs: today) },
            "todo lo que se cuenta es de hoy"
        )
    }

    // MARK: - Dobles

    private func apiMeal(timestamp: Date) -> MealApiDTO {
        MealApiDTO(
            id: UUID(), type: MealType.lunch.rawValue,
            timestamp: timestamp, items: [], myMealName: nil
        )
    }

    private final class FakeRemote: MealRemoteDataSourceProtocol {
        var mealsToReturn: [MealApiDTO] = []

        func createMeal(_ meal: Meal) async throws -> MealApiDTO { throw Boom.unused }
        func listMeals(for date: Date) async throws -> [MealApiDTO] { mealsToReturn }
        func listMeals(from start: Date, to end: Date) async throws -> [MealApiDTO] { mealsToReturn }
        func deleteMeal(id: UUID) async throws {}
        func foodByBarcode(_ barcode: String) async throws -> FoodApiDTO? { nil }
        func listFavorites() async throws -> [FoodApiDTO] { [] }
        func addFavorite(foodId: UUID) async throws {}
        func removeFavorite(foodId: UUID) async throws {}
        func createCustomFood(_ food: FoodItem) async throws -> FoodApiDTO { throw Boom.unused }
        func listMyMeals() async throws -> [MyMealApiDTO] { [] }
        func createMyMeal(_ myMeal: MyMeal) async throws -> MyMealApiDTO { throw Boom.unused }
        func deleteMyMeal(id: UUID) async throws {}
    }

    private enum Boom: Error { case unused }

    private final class FakeLocal: MealDataSourceProtocol {
        var meals: [MealDTO] = []
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
        func getFavorites() -> [FoodItemDTO] { [] }
        func saveFavorites(_ favorites: [FoodItemDTO]) {}
        func getMyMeals() -> [MyMealDTO] { [] }
        func saveMyMeals(_ meals: [MyMealDTO]) {}
        func getCustomFoods() -> [String: FoodItemDTO] { [:] }
        func saveCustomFoods(_ foods: [String: FoodItemDTO]) {}
    }

    private final class FakeOpenFoodFacts: OpenFoodFactsApiProtocol {
        func fetchProduct(barcode: String) async throws -> OpenFoodFactsProductDTO? { nil }
        func searchProducts(query: String, page: Int, pageSize: Int) async throws -> [OpenFoodFactsProductDTO] { [] }
    }

    private struct StubSession: AuthStateProviding {
        let authenticated: Bool
        var isAuthenticated: Bool { get async { authenticated } }
    }
}
