import Foundation

struct HealthDay: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var minutesOfExercise: Int = 0
    var steps: Int = 0
    var minutesStanding: Int = 0
    var dateWithFormat: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hoy"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "es_ES")
        dateFormatter.dateFormat = "d 'de' MMMM 'de' yyyy"
        return dateFormatter.string(from: date)
    }
}
