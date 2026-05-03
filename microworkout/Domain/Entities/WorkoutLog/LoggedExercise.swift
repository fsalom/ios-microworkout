import Foundation

public struct LoggedExercise: Identifiable, Equatable, Codable {
    public let id: UUID
    public var exercise: Exercise
    public var sets: [LoggedSet]
    public var notes: String?

    public init(
        id: UUID = UUID(),
        exercise: Exercise,
        sets: [LoggedSet] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.sets = sets
        self.notes = notes
    }
}
