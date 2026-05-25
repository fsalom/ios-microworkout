import Foundation

struct WorkoutLogDTO: Codable {
    var id: UUID
    var sessionId: UUID?
    var sessionName: String
    var startedAt: Date
    var endedAt: Date?
    var exercises: [LoggedExerciseDTO]
    var linkedHealthWorkoutId: UUID?
}

struct LoggedExerciseDTO: Codable {
    var id: UUID
    var exerciseId: UUID
    var exerciseName: String
    var exerciseType: String
    var sets: [LoggedSetDTO]
    var notes: String?
}

struct LoggedSetDTO: Codable {
    var id: UUID
    var weight: Double?
    var reps: Int?
    var rir: Float?
}
