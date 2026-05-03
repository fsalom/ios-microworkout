import Foundation

class WorkoutLogRepository: WorkoutLogRepositoryProtocol {
    private let local: WorkoutLogLocalDataSourceProtocol

    init(local: WorkoutLogLocalDataSourceProtocol) {
        self.local = local
    }

    func getAllSessions() -> [WorkoutSession] {
        local.getAllSessions().map { $0.toDomain() }
    }

    func saveSession(_ session: WorkoutSession) {
        local.saveSession(session.toDTO())
    }

    func deleteSession(id: String) {
        local.deleteSession(id: id)
    }

    func getAllLogs() -> [WorkoutLog] {
        local.getAllLogs().map { $0.toDomain() }
    }

    func saveLog(_ log: WorkoutLog) {
        local.saveLog(log.toDTO())
    }

    func deleteLog(id: String) {
        local.deleteLog(id: id)
    }
}

fileprivate extension WorkoutSessionDTO {
    func toDomain() -> WorkoutSession {
        let count = min(min(exerciseIds.count, exerciseNames.count), exerciseTypes.count)
        let exercises: [Exercise] = (0..<count).map { i in
            Exercise(id: exerciseIds[i], name: exerciseNames[i], type: exerciseTypes[i])
        }
        return WorkoutSession(
            id: id,
            name: name,
            exercises: exercises,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

fileprivate extension WorkoutSession {
    func toDTO() -> WorkoutSessionDTO {
        WorkoutSessionDTO(
            id: id,
            name: name,
            exerciseIds: exercises.map { $0.id },
            exerciseNames: exercises.map { $0.name },
            exerciseTypes: exercises.map { $0.type },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

fileprivate extension WorkoutLogDTO {
    func toDomain() -> WorkoutLog {
        WorkoutLog(
            id: id,
            sessionId: sessionId,
            sessionName: sessionName,
            startedAt: startedAt,
            endedAt: endedAt,
            exercises: exercises.map { $0.toDomain() },
            linkedHealthWorkoutId: linkedHealthWorkoutId
        )
    }
}

fileprivate extension WorkoutLog {
    func toDTO() -> WorkoutLogDTO {
        WorkoutLogDTO(
            id: id,
            sessionId: sessionId,
            sessionName: sessionName,
            startedAt: startedAt,
            endedAt: endedAt,
            exercises: exercises.map { $0.toDTO() },
            linkedHealthWorkoutId: linkedHealthWorkoutId
        )
    }
}

fileprivate extension LoggedExerciseDTO {
    func toDomain() -> LoggedExercise {
        LoggedExercise(
            id: id,
            exercise: Exercise(id: exerciseId, name: exerciseName, type: exerciseType),
            sets: sets.map { $0.toDomain() },
            notes: notes
        )
    }
}

fileprivate extension LoggedExercise {
    func toDTO() -> LoggedExerciseDTO {
        LoggedExerciseDTO(
            id: id,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            exerciseType: exercise.type,
            sets: sets.map { $0.toDTO() },
            notes: notes
        )
    }
}

fileprivate extension LoggedSetDTO {
    func toDomain() -> LoggedSet {
        LoggedSet(id: id, weight: weight, reps: reps, rir: rir)
    }
}

fileprivate extension LoggedSet {
    func toDTO() -> LoggedSetDTO {
        LoggedSetDTO(id: id, weight: weight, reps: reps, rir: rir)
    }
}
