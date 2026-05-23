import Foundation

protocol ExerciseProgressionUseCaseProtocol {
    /// Returns all past (and current) sets of the same exercise with the same weight
    /// and reps as the source set, that have at least one video. Sorted desc by date.
    /// Empty if the source set is not found or has no weight/reps.
    func videoMatches(forSetId setId: UUID) async -> [ExerciseProgressionMatch]
}
