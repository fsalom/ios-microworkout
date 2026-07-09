import Foundation

/// Auth-aware repository: guest → UserDefaults; authenticated → `/v1/sessions` + `/v1/logs`.
final class WorkoutLogRepository: WorkoutLogRepositoryProtocol {
    private let local: WorkoutLogLocalDataSourceProtocol
    private let remote: WorkoutLogRemoteDataSourceProtocol

    init(
        local: WorkoutLogLocalDataSourceProtocol,
        remote: WorkoutLogRemoteDataSourceProtocol
    ) {
        self.local = local
        self.remote = remote
    }

    private func isAuthenticated() async -> Bool {
        await MainActor.run { AuthSession.shared.state.isAuthenticated }
    }

    // MARK: Sessions

    func getAllSessions() async throws -> [WorkoutSession] {
        if await isAuthenticated() {
            return try await remote.listSessions().map { $0.toDomain() }
        }
        return local.getAllSessions().map { $0.toDomain() }
    }

    func saveSession(_ session: WorkoutSession) async throws {
        if await isAuthenticated() {
            _ = try await remote.upsertSession(session)
            return
        }
        local.saveSession(session.toDTO())
    }

    func deleteSession(id: String) async throws {
        if await isAuthenticated() {
            if let uuid = UUID(uuidString: id) {
                try await remote.deleteSession(id: uuid)
            }
            return
        }
        local.deleteSession(id: id)
    }

    // MARK: Logs

    func getAllLogs() async throws -> [WorkoutLog] {
        if await isAuthenticated() {
            return try await remote.listLogs().map { $0.toDomain() }
        }
        return local.getAllLogs().map { $0.toDomain() }
    }

    func saveLog(_ log: WorkoutLog) async throws {
        if await isAuthenticated() {
            _ = try await remote.upsertLog(log)
            return
        }
        local.saveLog(log.toDTO())
    }

    func deleteLog(id: String) async throws {
        if await isAuthenticated() {
            if let uuid = UUID(uuidString: id) {
                try await remote.deleteLog(id: uuid)
            }
            return
        }
        local.deleteLog(id: id)
    }

    func uploadLocalToRemote() async throws -> Int {
        var count = 0
        for dto in local.getAllSessions() {
            _ = try await remote.upsertSession(dto.toDomain()); count += 1
        }
        for dto in local.getAllLogs() {
            _ = try await remote.upsertLog(dto.toDomain()); count += 1
        }
        return count
    }
}

fileprivate extension WorkoutSessionDTO {
    func toDomain() -> WorkoutSession {
        let count = min(min(exerciseIds.count, exerciseNames.count), exerciseTypes.count)
        let exercises: [Exercise] = (0..<count).map { i in
            Exercise(id: exerciseIds[i], name: exerciseNames[i], type: ExerciseType(rawValue: exerciseTypes[i]) ?? .none)
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
            exerciseTypes: exercises.map { $0.type.rawValue },
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
            exercise: Exercise(id: exerciseId, name: exerciseName, type: ExerciseType(rawValue: exerciseType) ?? .none),
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
            exerciseType: exercise.type.rawValue,
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
