import Foundation

/// Partes de fecha para mostrar en la UI.
public struct DateParts: Equatable {
    public let day: Int
    public let month: Int
    public let year: Int
    public let monthName: String
}

fileprivate func word(_ count: Int, _ singular: String, _ plural: String) -> String {
    count == 1 ? singular : plural
}

/// Información de series agrupadas por ejercicio.
public struct ExerciseInfo: Identifiable {
    public let id: String      // mismo que exercise.id
    public let exercise: Exercise
    public let series: Int     // número de series registradas
}

/// Agrupa las entradas de entrenamiento de un día para mostrar en la UI.
public struct WorkoutEntryByDay: Identifiable, Equatable {
    public let id: String = UUID().uuidString
    /// Fecha ISO-8601 de inicio de día, ej: "2025-08-01T00:00:00Z"
    public let date: String
    public let entries: [WorkoutEntry]
    public let durationInSeconds: Int

    public init(date: String, entries: [WorkoutEntry], durationInSeconds: Int) {
        self.date = date
        self.entries = entries
        self.durationInSeconds = durationInSeconds
    }

    /// Número de ejercicios distintos registrados ese día.
    public var exercisesFormatted: String {
        "\(info.count) \(word(info.count, "ejercicio", "ejercicios"))"
    }

    /// Número total de series registradas ese día.
    public var totalSeriesFormatted: String {
        let total = info.reduce(0) { $0 + $1.series }
        return "\(total) \(word(total, "serie", "series"))"
    }

    /// Peso total levantado ese día (suma de weight * reps).
    public var totalWeightFormatted: String {
        let totalWeight = entries.reduce(0.0) { $0 + ($1.weight ?? 0.0) * Double($1.reps ?? 0) }
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 2
        fmt.minimumFractionDigits = 2
        let str = fmt.string(from: NSNumber(value: totalWeight)) ?? "\(totalWeight)"
        return "\(str) kg"
    }

    /// Fecha parseada a `Date` (ISO-8601) para orden y formateos.
    public var parsedDate: Date? {
        ISO8601DateFormatter().date(from: date)
    }

    /// Componentes de la fecha para mostrar en la UI (día, mes, año y nombre de mes).
    public var dateParts: DateParts? {
        guard let date = parsedDate else { return nil }
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let monthName = formatter.monthSymbols[month - 1]
        return DateParts(day: day, month: month, year: year, monthName: monthName)
    }

    /// Agrupa las entradas por ejercicio y cuenta cuántas series hay de cada uno.
    public var info: [ExerciseInfo] {
        let grouped = Dictionary(grouping: entries, by: { $0.exercise.id })
        return grouped.map { (exerciseID, list) in
            // tomamos cualquier WorkoutEntry para conocer el Exercise
            let exercise = list.first!.exercise
            return ExerciseInfo(id: exerciseID.uuidString, exercise: exercise, series: list.count)
        }
        .sorted { $0.exercise.name < $1.exercise.name }
    }

    /// Duración formateada: "Xm" o "Xh y Ym".
    public var durationFormatted: String {
        let minutes = max(0, durationInSeconds) / 60
        let hours = minutes / 60
        let mins = minutes % 60
        if hours == 0 {
            return "\(mins) \(word(mins, "minuto", "minutos"))"
        }
        return "\(hours) \(word(hours, "hora", "horas")) y \(mins) \(word(mins, "minuto", "minutos"))"
    }
}