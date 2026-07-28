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
            // Borrar también en local: una copia local huérfana se contaría como
            // pendiente en la siguiente sincronización y se volvería a subir.
            local.deleteSession(id: id)
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
            // Ver deleteSession: sin esto la copia local resucita al sincronizar.
            local.deleteLog(id: id)
            return
        }
        local.deleteLog(id: id)
    }

    /// Modelo espejo: cuenta las sesiones y registros locales cuyo id no está
    /// aún en la cuenta. No modifica nada local.
    func pendingSyncCount() async throws -> Int {
        let remoteSessionIds = Set(try await remote.listSessions().map { $0.id })
        let remoteLogIds = Set(try await remote.listLogs().map { $0.id })
        let pendingSessions = local.getAllSessions().filter { !remoteSessionIds.contains($0.id) }.count
        let pendingLogs = local.getAllLogs().filter { !remoteLogIds.contains($0.id) }.count
        return pendingSessions + pendingLogs
    }

    /// Sube las sesiones y registros locales que aún no estén en la cuenta (por id).
    /// Nunca borra la copia local — el dispositivo conserva el respaldo.
    func syncLocalToRemote() async throws -> Int {
        let remoteSessionIds = Set(try await remote.listSessions().map { $0.id })
        let remoteLogIds = Set(try await remote.listLogs().map { $0.id })
        var count = 0
        for dto in local.getAllSessions() where !remoteSessionIds.contains(dto.id) {
            _ = try await remote.upsertSession(dto.toDomain()); count += 1
        }
        for dto in local.getAllLogs() where !remoteLogIds.contains(dto.id) {
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
