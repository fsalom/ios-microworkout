import Foundation

struct LoggedExercise: Identifiable, Equatable {
    let id: String
    let exercise: Exercise
    var reps: Int
    var weight: Double
    var isCompleted: Bool = false
}
