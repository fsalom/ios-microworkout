import Foundation

struct HealthDay: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var minutesOfExercise: Int = 0
    var steps: Int = 0
    var minutesStanding: Int = 0
}
