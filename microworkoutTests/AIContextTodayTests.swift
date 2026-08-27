import XCTest
@testable import microworkout

/// El coach tiene que contar el día IGUAL que la cabecera de Comidas.
///
/// La pantalla suma el día completo (`getMeals(for:)`), pero el contexto del coach
/// pedía el rango `[hace N días, AHORA]`. Cualquier comida con hora posterior a la
/// actual —posible desde que la hora es editable— se caía del contexto y el coach
/// decía "has comido 1.289 kcal" con la pantalla mostrando 1.551 justo encima.
final class AIContextTodayTests: XCTestCase {

    /// Registra el rango que se le pide, para poder comprobar hasta dónde llega.
    private final class SpyMealUseCase: MealUseCaseProtocol, @unchecked Sendable {
        private let lock = NSLock()
        private var ranges: [(from: Date, to: Date)] = []
        var meals: [Meal] = []

        var lastRange: (from: Date, to: Date)? {
            lock.lock(); defer { lock.unlock() }
            return ranges.last
        }

        func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] {
            lock.lock(); ranges.append((startDate, endDate)); lock.unlock()
            // Como el repositorio de verdad: se recorta al rango pedido.
            return meals.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
        }

        func saveMeal(_ meal: Meal) async throws {}
        func getMealsForToday() async throws -> [Meal] { meals }
        func getMeals(for date: Date) async throws -> [Meal] {
            meals.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
        }
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

    // MARK: - Dobles mínimos del resto del contexto

    private struct StubProfile: UserProfileUseCaseProtocol {
        func saveProfile(_ profile: UserProfile) async throws {}
        func getProfile() async throws -> UserProfile? { nil }
        func setOnboardingCompleted(_ completed: Bool) {}
        func hasCompletedOnboarding() -> Bool { true }
    }

    private struct StubLogs: WorkoutLogUseCaseProtocol {
        func getAllSessions() async throws -> [WorkoutSession] { [] }
        func saveSession(_ session: WorkoutSession) async throws {}
        func deleteSession(id: String) async throws {}
        func getAllLogs() async throws -> [WorkoutLog] { [] }
        func saveLog(_ log: WorkoutLog) async throws {}
        func deleteLog(id: String) async throws {}
        func getPreviousLoggedExercise(
            sessionId: UUID?, exerciseId: UUID, beforeLogId: UUID?
        ) async throws -> (exercise: LoggedExercise, date: Date)? { nil }
    }

    private struct StubEntries: WorkoutEntryUseCaseProtocol {
        func getAll() async throws -> [WorkoutEntry] { [] }
        func getAll(for exerciseID: UUID) async throws -> [WorkoutEntry] { [] }
        func add(_ entry: WorkoutEntry) async throws {}
        func update(_ entry: WorkoutEntry) async throws {}
        func delete(entryID: UUID) async throws {}
        func deleteEntries(for day: WorkoutEntryByDay) async throws {}
        func getAllByDay() async throws -> [WorkoutEntryByDay] { [] }
        func groupByExercise(these entries: [WorkoutEntry]) -> [Exercise: [WorkoutEntry]] { [:] }
        func order(these entries: [WorkoutEntry]) -> [Exercise] { [] }
    }

    private struct StubHealth: HealthUseCaseProtocol {
        var isHealthDataAvailable: Bool { false }
        var authorizationStatus: HealthAuthorizationStatus { .notDetermined }
        func requestAuthorization() async throws -> Bool { false }
        func getDaysPerWeeksWithHealthInfo(for numberOfWeeks: Int) async throws -> [[HealthDay]] { [] }
        func getHealthInfoForToday() async throws -> HealthDay { HealthDay(date: Date()) }
        func getPreviousWeekAverageSteps() async throws -> Int { 0 }
        func getRecentWorkouts() async throws -> [HealthWorkout] { [] }
        func linkWorkout(_ workoutID: String, to trainingID: UUID) {}
        func unlinkWorkout(_ workoutID: String) {}
        func linkWorkout(_ workoutID: String, toEntryDate entryDate: String) {}
        func unlinkEntryFromWorkout(_ workoutID: String) {}
    }

    private struct StubTDEE: AdaptiveTDEEUseCaseProtocol {
        func estimate() async -> TDEEEstimate? { nil }
    }

    private struct StubWeeklyPlan: WeeklyPlanUseCaseProtocol {
        func getPlan() async throws -> WeeklyPlan { .empty }
        func savePlan(_ plan: WeeklyPlan) async throws {}
        func getResolvedWeek() async throws -> [ResolvedPlannedDay] { [] }
        func plannedDay(on date: Date) async throws -> ResolvedPlannedDay? { nil }
    }

    private func makeUseCase(_ meals: SpyMealUseCase) -> AIContextUseCase {
        AIContextUseCase(
            userProfileUseCase: StubProfile(),
            workoutLogUseCase: StubLogs(),
            workoutEntryUseCase: StubEntries(),
            mealUseCase: meals,
            healthUseCase: StubHealth(),
            weeklyPlanUseCase: StubWeeklyPlan(),
            adaptiveTDEEUseCase: StubTDEE()
        )
    }

    private func meal(at hour: Int, kcal: Double) -> Meal {
        let timestamp = Calendar.current.date(
            bySettingHour: hour, minute: 0, second: 0, of: Date()
        )!
        return Meal(
            type: .lunch,
            timestamp: timestamp,
            items: [
                FoodItem(
                    name: "Comida",
                    nutritionPer100g: NutritionInfo(
                        calories: kcal, carbohydrates: 0, proteins: 0, fats: 0, fiber: nil
                    ),
                    quantity: 100
                )
            ]
        )
    }

    // MARK: - El rango llega al final del día

    func testTheMealRangeCoversTheWholeDayNotJustUntilNow() async throws {
        let spy = SpyMealUseCase()
        let context = await makeUseCase(spy).buildContext(mealDaysBack: 14, healthWeeksBack: 1)
        _ = context

        let range = try XCTUnwrap(spy.lastRange)
        let calendar = Calendar.current
        XCTAssertTrue(
            calendar.isDate(range.to, inSameDayAs: Date()),
            "el final del rango sigue siendo hoy"
        )
        XCTAssertEqual(
            calendar.component(.hour, from: range.to), 23,
            "y llega al final del día, no al instante actual"
        )
    }

    /// El caso del bug: una comida fechada MÁS TARDE que ahora tiene que contar,
    /// porque la cabecera de Comidas la cuenta.
    func testAMealTimedLaterThanNowStillCounts() async throws {
        let spy = SpyMealUseCase()
        // Una a primera hora y otra a las 23:00, que casi siempre es "más tarde que
        // ahora" cuando corren los tests.
        spy.meals = [meal(at: 1, kcal: 300), meal(at: 23, kcal: 700)]

        let context = await makeUseCase(spy).buildContext(mealDaysBack: 14, healthWeeksBack: 1)

        let todayKcal = context.meals
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0.0) { $0 + $1.totalNutrition.calories }
        XCTAssertEqual(
            todayKcal, 1_000, accuracy: 0.01,
            "el coach tiene que sumar lo mismo que la pantalla, incluida la comida de las 23:00"
        )
    }
}
