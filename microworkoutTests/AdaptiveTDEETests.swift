import XCTest
@testable import microworkout

/// El gasto real medido con los registros del usuario.
///
/// El número acaba propuesto como objetivo y delante del coach, así que aquí lo
/// que se vigila es que NO se invente autoridad: con datos insuficientes o
/// contaminados (días a medio registrar), la respuesta correcta es `nil`, no un
/// gasto con decimales.
final class AdaptiveTDEETests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }

    private func day(_ offset: Int, from reference: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: reference)!
    }

    /// 28 días de ingesta constante y pesadas cada dos días siguiendo una recta.
    private func makeData(
        intakeKcal: Double,
        weeklyChangeKg: Double,
        startKg: Double = 80,
        now: Date
    ) -> (intake: [Date: Double], weights: [(date: Date, kg: Double)]) {
        var intake: [Date: Double] = [:]
        var weights: [(date: Date, kg: Double)] = []
        let dailyChange = weeklyChangeKg / 7
        for offset in stride(from: -27, through: 0, by: 1) {
            let date = day(offset, from: now)
            intake[calendar.startOfDay(for: date)] = intakeKcal
            if offset % 2 == 0 {
                weights.append((date: date, kg: startKg + dailyChange * Double(offset + 27)))
            }
        }
        return (intake, weights)
    }

    // MARK: - La aritmética del balance

    func testLosingWeightMeansExpenditureAboveIntake() throws {
        let now = Date()
        let data = makeData(intakeKcal: 2_000, weeklyChangeKg: -0.3, now: now)
        let estimate = try XCTUnwrap(AdaptiveTDEECalculator.estimate(
            intakeByDay: data.intake, weighIns: data.weights, now: now, calendar: calendar
        ))
        // 2.000 comidas perdiendo 0,3 kg/sem (330 kcal/día) → gastas ~2.330.
        XCTAssertEqual(estimate.tdee, 2_330, accuracy: 15)
        XCTAssertEqual(estimate.weeklyChangeKg, -0.3, accuracy: 0.02)
        XCTAssertEqual(estimate.meanDailyIntake, 2_000, accuracy: 0.1)
    }

    func testGainingWeightMeansExpenditureBelowIntake() throws {
        let now = Date()
        let data = makeData(intakeKcal: 2_800, weeklyChangeKg: 0.2, now: now)
        let estimate = try XCTUnwrap(AdaptiveTDEECalculator.estimate(
            intakeByDay: data.intake, weighIns: data.weights, now: now, calendar: calendar
        ))
        XCTAssertEqual(estimate.tdee, 2_580, accuracy: 15)
    }

    /// El ruido de agua (±0,4 kg alternos) no puede mover el resultado: para eso
    /// la tendencia es una regresión y no "última pesada menos primera".
    func testWaterNoiseDoesNotSwingTheEstimate() throws {
        let now = Date()
        var data = makeData(intakeKcal: 2_000, weeklyChangeKg: -0.3, now: now)
        data.weights = data.weights.enumerated().map { index, sample in
            (date: sample.date, kg: sample.kg + (index.isMultiple(of: 2) ? 0.4 : -0.4))
        }
        let estimate = try XCTUnwrap(AdaptiveTDEECalculator.estimate(
            intakeByDay: data.intake, weighIns: data.weights, now: now, calendar: calendar
        ))
        XCTAssertEqual(estimate.tdee, 2_330, accuracy: 60)
    }

    // MARK: - Días a medio registrar

    /// Un día con un café anotado no es un día de 300 kcal: contar esos días
    /// hunde la ingesta media y el gasto sale bajo → la app recomendaría comer
    /// menos justo a quien registra a medias.
    func testHalfLoggedDaysAreExcludedFromTheMean() throws {
        let now = Date()
        var data = makeData(intakeKcal: 2_000, weeklyChangeKg: -0.3, now: now)
        // Cinco días "de café": por debajo del umbral de plausibilidad.
        for offset in [-3, -7, -11, -15, -19] {
            data.intake[calendar.startOfDay(for: day(offset, from: now))] = 300
        }
        let estimate = try XCTUnwrap(AdaptiveTDEECalculator.estimate(
            intakeByDay: data.intake, weighIns: data.weights, now: now, calendar: calendar
        ))
        XCTAssertEqual(estimate.meanDailyIntake, 2_000, accuracy: 0.1)
        // 27 días dentro del tramo de pesadas (el día -27 queda fuera: la primera
        // pesada es del -26) menos los 5 de café.
        XCTAssertEqual(estimate.loggedDays, 22)
    }

    // MARK: - Sin datos suficientes, la respuesta es nil

    func testTooFewLoggedDaysGivesNoEstimate() {
        let now = Date()
        var data = makeData(intakeKcal: 2_000, weeklyChangeKg: -0.3, now: now)
        // Deja solo 10 días registrados (el mínimo son 14).
        data.intake = Dictionary(uniqueKeysWithValues: data.intake.sorted { $0.key < $1.key }.prefix(10).map { ($0.key, $0.value) })
        XCTAssertNil(AdaptiveTDEECalculator.estimate(
            intakeByDay: data.intake, weighIns: data.weights, now: now, calendar: calendar
        ))
    }

    func testTooFewWeighInsGivesNoEstimate() {
        let now = Date()
        var data = makeData(intakeKcal: 2_000, weeklyChangeKg: -0.3, now: now)
        data.weights = Array(data.weights.prefix(3))
        XCTAssertNil(AdaptiveTDEECalculator.estimate(
            intakeByDay: data.intake, weighIns: data.weights, now: now, calendar: calendar
        ))
    }

    /// Cuatro pesadas en tres días no miden una tendencia: hace falta recorrido.
    func testShortWeightSpanGivesNoEstimate() {
        let now = Date()
        var data = makeData(intakeKcal: 2_000, weeklyChangeKg: -0.3, now: now)
        data.weights = data.weights.filter { $0.date >= day(-3, from: now) }
        XCTAssertNil(AdaptiveTDEECalculator.estimate(
            intakeByDay: data.intake, weighIns: data.weights, now: now, calendar: calendar
        ))
    }

    /// Registro roto (p. ej. una comida con 90.000 kcal) → el resultado se sale
    /// del rango humano y se descarta entero, no se enseña con autoridad.
    func testInsaneResultIsDiscarded() {
        let now = Date()
        let data = makeData(intakeKcal: 9_000, weeklyChangeKg: -0.3, now: now)
        XCTAssertNil(AdaptiveTDEECalculator.estimate(
            intakeByDay: data.intake, weighIns: data.weights, now: now, calendar: calendar
        ))
    }

    // MARK: - Del gasto al objetivo

    func testSuggestedTargetAppliesTheGoalAdjustment() {
        let estimate = TDEEEstimate(
            tdee: 2_350, weeklyChangeKg: -0.3, meanDailyIntake: 2_000,
            loggedDays: 20, weighInCount: 10, spanDays: 26
        )
        XCTAssertEqual(estimate.suggestedTarget(for: .loseWeight), 1_850)
        XCTAssertEqual(estimate.suggestedTarget(for: .maintain), 2_350)
        XCTAssertEqual(estimate.suggestedTarget(for: .gainMuscle), 2_650)
    }

    // MARK: - El use case suma por día local

    private final class StubMeals: MealUseCaseProtocol {
        var meals: [Meal] = []
        func saveMeal(_ meal: Meal) async throws {}
        func getMealsForToday() async throws -> [Meal] { [] }
        func getMeals(for date: Date) async throws -> [Meal] { [] }
        func getMeals(from startDate: Date, to endDate: Date) async throws -> [Meal] { meals }
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

    private final class StubMetrics: BodyMetricsUseCaseProtocol {
        var metrics: [DailyMetrics] = []
        func getRecent(days: Int) async throws -> [DailyMetrics] { metrics }
        func saveWeight(_ kilograms: Double, on date: Date) async throws {}
        func delete(date: Date) async throws {}
        func latestWeight() async throws -> Double? { nil }
    }

    /// Dos comidas del mismo día se suman; con eso el día pasa el umbral aunque
    /// cada comida por separado no llegue.
    func testUseCaseAggregatesMealsPerLocalDay() async {
        let now = Date()
        let meals = StubMeals()
        let metrics = StubMetrics()

        for offset in stride(from: -27, through: 0, by: 1) {
            let date = day(offset, from: now)
            // Dos comidas de 1.000: por separado no llegan al umbral doble, juntas sí.
            for hour in [10.0, 20.0] {
                meals.meals.append(Meal(
                    type: .lunch,
                    timestamp: date.addingTimeInterval(hour * 60),
                    items: [FoodItem(
                        name: "Comida",
                        nutritionPer100g: NutritionInfo(calories: 1_000, carbohydrates: 0, proteins: 0, fats: 0),
                        quantity: 100
                    )]
                ))
            }
            if offset % 2 == 0 {
                metrics.metrics.append(DailyMetrics(
                    date: date, weightKg: 80 - 0.04 * Double(-offset), source: .manual
                ))
            }
        }

        let useCase = AdaptiveTDEEUseCase(mealUseCase: meals, bodyMetricsUseCase: metrics)
        let estimate = await useCase.estimate()
        XCTAssertNotNil(estimate)
        XCTAssertEqual(estimate?.meanDailyIntake ?? 0, 2_000, accuracy: 0.1)
    }
}
