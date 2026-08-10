import XCTest
@testable import microworkout

/// La hora de una comida se puede equivocar de forma invisible: si un cambio de
/// hora empuja la comida a otro día, desaparece de la pantalla y nadie sabe por
/// qué. Estos tests fijan esa aritmética.
final class MealTimeTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }

    /// Fechas fijas: un test de horas que dependa de cuándo se ejecuta es un test
    /// que falla de noche.
    private func at(_ iso: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return formatter.date(from: iso)!
    }

    private func hhmmss(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return formatter.string(from: date)
    }

    // MARK: - Llevar la hora elegida al día que se registra

    /// El selector solo muestra hora y minuto, así que la fecha que trae es la de
    /// hoy. Registrando la cena de ayer, usarla tal cual movería la comida a hoy.
    func testThePickedTimeLandsOnTheDayBeingLogged() {
        let picked = at("2026-08-10 21:30:00")      // el selector trae "hoy"
        let loggingDay = at("2026-08-07 12:00:00")  // pero se registra el día 7

        let result = MealTime.time(picked, onDay: loggingDay, calendar: calendar)

        XCTAssertEqual(hhmmss(result), "2026-08-07 21:30:00")
    }

    func testThePickedTimeDropsSeconds() {
        let result = MealTime.time(
            at("2026-08-10 14:30:47"), onDay: at("2026-08-10 09:00:00"), calendar: calendar
        )
        XCTAssertEqual(hhmmss(result), "2026-08-10 14:30:00", "la hora elegida es hora y minuto")
    }

    // MARK: - Desplazar una sección

    /// Se desplazan todas por igual, no se igualan: cada alimento añadido es un
    /// registro propio y aplanarlos perdería el orden en que se comieron.
    func testShiftingASectionKeepsTheGapsBetweenItsMeals() {
        let day = at("2026-08-10 00:00:00")
        let timestamps = [
            at("2026-08-10 09:00:00"),
            at("2026-08-10 09:02:30"),
            at("2026-08-10 09:05:00"),
        ]

        let result = MealTime.shifted(
            timestamps, anchoringEarliestAt: at("2026-08-10 14:00:00"),
            within: day, calendar: calendar
        )

        XCTAssertEqual(result.map(hhmmss), [
            "2026-08-10 14:00:00",
            "2026-08-10 14:02:30",
            "2026-08-10 14:05:00",
        ], "la hora elegida es la del primero; los huecos se conservan")
    }

    func testTheOrderOfTheResultMatchesTheInput() {
        let day = at("2026-08-10 00:00:00")
        // A propósito desordenado: quien llame no tiene que ordenar antes.
        let timestamps = [at("2026-08-10 09:05:00"), at("2026-08-10 09:00:00")]

        let result = MealTime.shifted(
            timestamps, anchoringEarliestAt: at("2026-08-10 20:00:00"),
            within: day, calendar: calendar
        )

        XCTAssertEqual(result.map(hhmmss), [
            "2026-08-10 20:05:00",
            "2026-08-10 20:00:00",
        ], "mismo orden que la entrada, anclando la MÁS TEMPRANA")
    }

    /// Lo que este recorte evita: una comida empujada más allá de medianoche se va
    /// a otro día y desaparece de la pantalla sin explicación.
    func testNoMealIsPushedOutOfTheDay() {
        let day = at("2026-08-10 00:00:00")
        let timestamps = [
            at("2026-08-10 08:00:00"),
            at("2026-08-10 20:00:00"),   // 12 h después del primero
        ]

        // Fijando el primero a las 23:50, el segundo caería el día 11.
        let result = MealTime.shifted(
            timestamps, anchoringEarliestAt: at("2026-08-10 23:50:00"),
            within: day, calendar: calendar
        )

        XCTAssertEqual(result.map(hhmmss), [
            "2026-08-10 23:50:00",
            "2026-08-10 23:59:59",
        ], "se recorta al final del día en vez de saltar al siguiente")
    }

    func testMovingBackwardsAlsoStaysInsideTheDay() {
        let day = at("2026-08-10 00:00:00")
        let timestamps = [at("2026-08-10 14:00:00"), at("2026-08-10 02:00:00")]

        let result = MealTime.shifted(
            timestamps, anchoringEarliestAt: at("2026-08-10 00:10:00"),
            within: day, calendar: calendar
        )

        XCTAssertEqual(result.map(hhmmss), [
            "2026-08-10 12:10:00",
            "2026-08-10 00:10:00",
        ])
        XCTAssertTrue(result.allSatisfy { calendar.isDate($0, inSameDayAs: day) })
    }

    func testAnEmptySectionShiftsToNothing() {
        XCTAssertTrue(
            MealTime.shifted([], anchoringEarliestAt: Date(), within: Date(), calendar: calendar).isEmpty
        )
    }

    // MARK: - No reescribir por nada

    /// El selector emite el valor que ya tenía al aparecer. Sin esta comprobación,
    /// cada render reescribiría —y resubiría— todas las comidas de la sección.
    func testTheSameTimeIsNotAChange() {
        let day = at("2026-08-10 00:00:00")
        let timestamps = [at("2026-08-10 09:00:00"), at("2026-08-10 09:03:00")]

        XCTAssertFalse(
            MealTime.changes(
                timestamps, movingEarliestTo: at("2026-08-10 09:00:00"),
                within: day, calendar: calendar
            )
        )
        XCTAssertTrue(
            MealTime.changes(
                timestamps, movingEarliestTo: at("2026-08-10 09:01:00"),
                within: day, calendar: calendar
            )
        )
    }

    /// Los segundos del registro no cuentan: el selector no los puede expresar, así
    /// que "09:00:42 → 09:00" no es un cambio que el usuario haya pedido.
    func testSecondsAloneAreNotAChange() {
        let day = at("2026-08-10 00:00:00")
        XCTAssertFalse(
            MealTime.changes(
                [at("2026-08-10 09:00:42")], movingEarliestTo: at("2026-08-10 09:00:00"),
                within: day, calendar: calendar
            ),
            "42 s de diferencia no es una edición"
        )
    }
}
