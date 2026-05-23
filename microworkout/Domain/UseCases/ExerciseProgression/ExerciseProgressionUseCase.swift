import Foundation

final class ExerciseProgressionUseCase: ExerciseProgressionUseCaseProtocol {
    private let logUseCase: WorkoutLogUseCaseProtocol
    private let mediaUseCase: SetMediaUseCase

    init(logUseCase: WorkoutLogUseCaseProtocol, mediaUseCase: SetMediaUseCase) {
        self.logUseCase = logUseCase
        self.mediaUseCase = mediaUseCase
    }

    func videoMatches(forSetId setId: UUID) async -> [ExerciseProgressionMatch] {
        let logs = logUseCase.getAllLogs()

        // 1) Find the source set to anchor the search criteria.
        guard let source = findSource(setId: setId, in: logs),
              let sourceWeight = source.set.weight,
              let sourceReps = source.set.reps else {
            return []
        }

        // 2) Walk every log and collect sets that match (exercise.id, weight, reps).
        var matches: [ExerciseProgressionMatch] = []
        for log in logs {
            for exerciseLog in log.exercises where exerciseLog.exercise.id == source.exerciseId {
                for set in exerciseLog.sets where set.weight == sourceWeight && set.reps == sourceReps {
                    let media = (try? await mediaUseCase.getMedia(forSetId: set.id)) ?? []
                    let videos = media.filter { $0.type == .video }
                    guard !videos.isEmpty else { continue }
                    matches.append(
                        ExerciseProgressionMatch(
                            setId: set.id,
                            logId: log.id,
                            date: log.startedAt,
                            exerciseName: exerciseLog.exercise.name,
                            weight: set.weight,
                            reps: set.reps,
                            rir: set.rir,
                            tags: set.tags,
                            media: videos,
                            isCurrent: set.id == setId
                        )
                    )
                }
            }
        }

        return matches.sorted { $0.date > $1.date }
    }

    private struct SourceSet {
        let exerciseId: UUID
        let set: LoggedSet
    }

    private func findSource(setId: UUID, in logs: [WorkoutLog]) -> SourceSet? {
        for log in logs {
            for exerciseLog in log.exercises {
                if let set = exerciseLog.sets.first(where: { $0.id == setId }) {
                    return SourceSet(exerciseId: exerciseLog.exercise.id, set: set)
                }
            }
        }
        return nil
    }
}
