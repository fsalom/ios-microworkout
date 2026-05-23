import Foundation

/// One past (or current) set with the same exercise + weight + reps that has video media.
/// Used to show a "video progression" timeline across days.
public struct ExerciseProgressionMatch: Identifiable, Equatable {
    public let id: UUID
    public let setId: UUID
    public let logId: UUID
    public let date: Date
    public let exerciseName: String
    public let weight: Double?
    public let reps: Int?
    public let rir: Float?
    public let tags: [SetTag]
    public let media: [SetMedia]
    /// True when this match corresponds to the set the user started the comparison from.
    public let isCurrent: Bool

    public init(
        setId: UUID,
        logId: UUID,
        date: Date,
        exerciseName: String,
        weight: Double?,
        reps: Int?,
        rir: Float?,
        tags: [SetTag],
        media: [SetMedia],
        isCurrent: Bool
    ) {
        self.id = setId
        self.setId = setId
        self.logId = logId
        self.date = date
        self.exerciseName = exerciseName
        self.weight = weight
        self.reps = reps
        self.rir = rir
        self.tags = tags
        self.media = media
        self.isCurrent = isCurrent
    }
}
