import Foundation

struct LoggedExercise: Identifiable, Equatable {
    let id: String
    let exercise: Exercise
    var reps: Int
    var weight: Double
    var isCompleted: Bool = false
}

struct DateParts: Equatable {
    let day: Int
    let month: Int
    let year: Int
    let monthName: String
}

struct LoggedExerciseByDay: Identifiable, Equatable {
    let id: String = UUID().uuidString
    let date: String                    // ISO-8601, ej: "2025-08-01T17:45:12Z"
    let exercises: [LoggedExercise]
    let durationInSeconds: Int

    var exercisesFormatted: String {
        return "\(exercises.count) \(word(exercises.count, "ejercicio", "ejercicios"))"
    }

    var durationFormatted: String {
        let totalMinutes = max(0, durationInSeconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60



        if hours == 0 {
            return "\(minutes) \(word(minutes, "minuto", "minutos"))"
        }
        return "\(hours) \(word(hours, "hora", "horas")) y \(minutes) \(word(minutes, "minuto", "minutos"))"
    }

    var dateFormatted: String {
        return formatISOToSpanish(date)!
    }

    var dateParts: DateParts? {
        let timeZone = TimeZone.current   // o TimeZone(identifier: "Europe/Madrid")!
        let iso = ISO8601DateFormatter()
        guard let d = iso.date(from: date) else { return nil }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone

        let comps = cal.dateComponents([.day, .month, .year], from: d)
        guard let day = comps.day, let month = comps.month, let year = comps.year else {
            return nil
        }

        let df = DateFormatter()
        df.locale = Locale(identifier: "es_ES")
        df.timeZone = timeZone
        df.dateFormat = "MMMM"
        let monthName = df.string(from: d).lowercased()

        return DateParts(day: day, month: month, year: year, monthName: monthName)
    }

    private func formatISOToSpanish(_ isoString: String,
                                    timeZone: TimeZone = .current) -> String? {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: isoString) else { return nil }
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_ES")
        df.timeZone = timeZone
        df.dateFormat = "d 'de' MMMM 'de' y"
        return df.string(from: date)
    }

    private func word(_ n: Int, _ singular: String, _ plural: String) -> String {
        n == 1 ? singular : plural
    }
}
