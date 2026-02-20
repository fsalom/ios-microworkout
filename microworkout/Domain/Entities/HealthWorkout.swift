import Foundation

struct HealthWorkout: Identifiable, Equatable, Codable {
    let id: String                    // HKWorkout.uuid.uuidString
    let activityTypeName: String      // "Carrera", "Fuerza", etc.
    let startDate: Date
    let endDate: Date
    let durationInSeconds: Double
    let totalCalories: Double?
    let totalDistance: Double?         // metros
    let averageHeartRate: Double?     // bpm
    var linkedTrainingID: UUID?       // link a Training.id

    var durationFormatted: String {
        let totalMinutes = Int(durationInSeconds) / 60
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours == 0 {
            return "\(mins) min"
        }
        return "\(hours)h \(mins)m"
    }

    var dateParts: DateParts? {
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.component(.day, from: startDate)
        let month = calendar.component(.month, from: startDate)
        let year = calendar.component(.year, from: startDate)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let monthName = formatter.monthSymbols[month - 1]
        return DateParts(day: day, month: month, year: year, monthName: monthName)
    }

    var caloriesFormatted: String? {
        guard let cal = totalCalories else { return nil }
        return "\(Int(cal)) kcal"
    }

    var distanceFormatted: String? {
        guard let dist = totalDistance, dist > 0 else { return nil }
        if dist >= 1000 {
            return String(format: "%.2f km", dist / 1000)
        }
        return "\(Int(dist)) m"
    }

    var heartRateFormatted: String? {
        guard let hr = averageHeartRate else { return nil }
        return "\(Int(hr)) bpm"
    }

    var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}
