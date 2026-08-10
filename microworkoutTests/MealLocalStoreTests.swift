import XCTest
@testable import microworkout

/// La copia en el dispositivo es la única que tiene lo registrado como invitado, y
/// se lee filtrando por día. Aquí se prueba el almacén DE VERDAD (no un doble):
/// que lo guardado vuelve, que vuelve en su día, y que sobrevive al viaje por JSON.
///
/// Lo último importa más de lo que parece: `UserDefaultsManager.get` decodifica con
/// `try?`, así que si el JSON guardado dejara de encajar con el DTO no habría error
/// — devolvería `nil` y desaparecerían TODAS las comidas de golpe, en silencio.
final class MealLocalStoreTests: XCTestCase {

    /// Un almacén propio por test: `UserDefaults.standard` es compartido y los tests
    /// corren en paralelo.
    private func makeDataSource() -> MealLocalDataSource {
        let suite = UserDefaults(suiteName: "meals-test-\(UUID().uuidString)")!
        return MealLocalDataSource(storage: UserDefaultsManager(defaults: suite))
    }

    private func meal(hour: Int, dayOffset: Int = 0, name: String = "Pollo") -> MealDTO {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: dayOffset, to: Date())!
        let timestamp = calendar.date(bySettingHour: hour, minute: 30, second: 15, of: day)!
        return MealDTO(
            id: UUID(),
            type: MealType.lunch.rawValue,
            timestamp: timestamp,
            items: [
                FoodItemDTO(
                    id: UUID(), name: name, barcode: "123",
                    nutritionPer100g: NutritionInfoDTO(
                        calories: 165, carbohydrates: 0, proteins: 31, fats: 3.6, fiber: nil
                    ),
                    quantity: 150, servingSize: nil, imageUrl: nil
                )
            ],
            myMealName: nil
        )
    }

    func testAMealSavedAsGuestComesBackForItsOwnDay() async throws {
        let local = makeDataSource()
        let lunch = meal(hour: 14)

        try await local.saveMeal(lunch)

        let today = try await local.getMeals(for: Date())
        XCTAssertEqual(today.map(\.id), [lunch.id])
    }

    func testAMealFromAnotherDayIsNotReturnedForToday() async throws {
        let local = makeDataSource()
        let yesterday = meal(hour: 14, dayOffset: -1)
        let today = meal(hour: 14)

        try await local.saveMeal(yesterday)
        try await local.saveMeal(today)

        let forToday = try await local.getMeals(for: Date())
        XCTAssertEqual(forToday.map(\.id), [today.id], "cada comida en su día")

        let all = try await local.getAllMeals()
        XCTAssertEqual(all.count, 2, "pero las dos siguen guardadas")
    }

    /// Los extremos del día son donde el filtrado se rompe si alguien cambia
    /// `isDate(inSameDayAs:)` por una comparación a mano.
    func testMealsAtTheEdgesOfTheDayBelongToThatDay() async throws {
        let local = makeDataSource()
        let earlyMorning = meal(hour: 0)
        let lateNight = meal(hour: 23)

        try await local.saveMeal(earlyMorning)
        try await local.saveMeal(lateNight)

        let today = try await local.getMeals(for: Date())
        XCTAssertEqual(
            Set(today.map(\.id)), Set([earlyMorning.id, lateNight.id]),
            "las 00:30 y las 23:30 son el mismo día"
        )
    }

    /// Un `save` del mismo id reemplaza en vez de duplicar. Es lo que hace que
    /// cambiar la hora de una comida no la clone.
    func testSavingTheSameMealAgainReplacesIt() async throws {
        let local = makeDataSource()
        var lunch = meal(hour: 14)
        try await local.saveMeal(lunch)

        lunch.timestamp = Calendar.current.date(
            bySettingHour: 16, minute: 0, second: 0, of: Date()
        )!
        try await local.saveMeal(lunch)

        let all = try await local.getAllMeals()
        XCTAssertEqual(all.count, 1, "upsert por id, no se duplica")
        XCTAssertEqual(Calendar.current.component(.hour, from: all[0].timestamp), 16)
    }

    /// El viaje completo por JSON con `Date` en ISO8601. Si esto falla, en la app no
    /// hay error: hay cero comidas.
    func testEverythingSurvivesTheRoundTripThroughStorage() async throws {
        let local = makeDataSource()
        let lunch = meal(hour: 14, name: "Merluza")

        try await local.saveMeal(lunch)

        let all = try await local.getAllMeals()
        let restored = try XCTUnwrap(all.first)
        XCTAssertEqual(restored.id, lunch.id)
        XCTAssertEqual(restored.type, MealType.lunch.rawValue)
        XCTAssertEqual(restored.items.first?.name, "Merluza")
        XCTAssertEqual(restored.items.first?.nutritionPer100g.proteins, 31)
        XCTAssertNil(restored.items.first?.nutritionPer100g.fiber)
        XCTAssertEqual(
            restored.timestamp.timeIntervalSince1970,
            lunch.timestamp.timeIntervalSince1970,
            accuracy: 1,
            "la fecha vuelve igual: si se desplazara, la comida cambiaría de día"
        )
    }
}
