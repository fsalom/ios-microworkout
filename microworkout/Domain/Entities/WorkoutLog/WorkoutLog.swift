import Foundation

public struct WorkoutLog: Identifiable, Equatable, Codable {
    public let id: UUID
    public var sessionId: UUID?
    public var sessionName: String
    public var startedAt: Date
    public var endedAt: Date?
    public var exercises: [LoggedExercise]
    public var linkedHealthWorkoutId: UUID?

    public init(
        id: UUID = UUID(),
        sessionId: UUID? = nil,
        sessionName: String,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        exercises: [LoggedExercise] = [],
        linkedHealthWorkoutId: UUID? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.sessionName = sessionName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.exercises = exercises
        self.linkedHealthWorkoutId = linkedHealthWorkoutId
    }
}

public extension WorkoutLog {
    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets.count } }

    var durationSeconds: Int {
        guard let end = endedAt else { return 0 }
        return Int(end.timeIntervalSince(startedAt))
    }

    var durationFormatted: String {
        let total = durationSeconds
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)min" }
        return "\(m)min"
    }
}
