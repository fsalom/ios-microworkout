import Foundation

/// Wire-level types matching the FastAPI backend at `/v1/sessions` and `/v1/logs`.
/// The backend uses snake_case; we map to camelCase here via CodingKeys.

struct LoggedSetApiDTO: Codable {
    let id: UUID
    let weight: Double?
    let reps: Int?
    let rir: Float?
    let tags: [String]
}

struct LoggedExerciseApiDTO: Codable {
    let id: UUID
    let exerciseId: UUID
    let exerciseName: String
    let exerciseType: String
    let notes: String?
    let sets: [LoggedSetApiDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case exerciseType = "exercise_type"
        case notes
        case sets
    }
}

struct WorkoutLogApiDTO: Codable {
    let id: UUID
    let sessionId: UUID?
    let sessionName: String
    let startedAt: Date
    let endedAt: Date?
    let linkedHealthWorkoutId: String?
    let exercises: [LoggedExerciseApiDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case sessionName = "session_name"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case linkedHealthWorkoutId = "linked_health_workout_id"
        case exercises
    }
}

struct WorkoutSessionExerciseApiDTO: Codable {
    let exerciseId: UUID
    let exerciseName: String
    let exerciseType: String

    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case exerciseName = "exercise_name"
        case exerciseType = "exercise_type"
    }
}

struct WorkoutSessionApiDTO: Codable {
    let id: UUID
    let name: String
    let exercises: [WorkoutSessionExerciseApiDTO]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, exercises
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Mapping to domain

extension WorkoutLogApiDTO {
    func toDomain() -> WorkoutLog {
        WorkoutLog(
            id: id,
            sessionId: sessionId,
            sessionName: sessionName,
            startedAt: startedAt,
            endedAt: endedAt,
            exercises: exercises.map { $0.toDomain() },
            linkedHealthWorkoutId: linkedHealthWorkoutId.flatMap { UUID(uuidString: $0) }
        )
    }
}

extension LoggedExerciseApiDTO {
    func toDomain() -> LoggedExercise {
        LoggedExercise(
            id: id,
            exercise: Exercise(
                id: exerciseId,
                name: exerciseName,
                type: ExerciseType(rawValue: exerciseType) ?? .none
            ),
            sets: sets.map { $0.toDomain() },
            notes: notes
        )
    }
}

extension LoggedSetApiDTO {
    func toDomain() -> LoggedSet {
        LoggedSet(
            id: id,
            weight: weight,
            reps: reps,
            rir: rir,
            tags: tags.compactMap { SetTag(rawValue: $0) }
        )
    }
}

extension WorkoutSessionApiDTO {
    func toDomain() -> WorkoutSession {
        WorkoutSession(
            id: id,
            name: name,
            exercises: exercises.map { entry in
                Exercise(
                    id: entry.exerciseId,
                    name: entry.exerciseName,
                    type: ExerciseType(rawValue: entry.exerciseType) ?? .none
                )
            },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
