import Foundation
// `NetworkError` vive en TripleA: hace falta para distinguir un 404 del servidor
// de un fallo de red al borrar.
import TripleA

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
        let stored = local.getAllSessions().map { $0.toDomain() }
        guard await isAuthenticated() else { return stored }

        // Se fusiona en vez de devolver solo lo remoto. Devolver solo el servidor
        // hacía DESAPARECER de la pantalla todo lo registrado como invitado: si la
        // subida al entrar en la cuenta falló (o aún no había pasado), lo local
        // seguía en el dispositivo pero nadie lo veía, y eso se lee como "he
        // perdido mis entrenos". Un fallo del servidor degrada a local por lo
        // mismo: esconder el historial es peor que mostrar solo una parte.
        let synced = (try? await remote.listSessions())?.map { $0.toDomain() } ?? []
        let syncedIds = Set(synced.map { $0.id })
        return synced + stored.filter { !syncedIds.contains($0.id) }
    }

    func saveSession(_ session: WorkoutSession) async throws {
        guard await isAuthenticated() else {
            return local.saveSession(session.toDTO())
        }
        do {
            _ = try await remote.upsertSession(session)
        } catch {
            // Si el servidor no está, se guarda en el dispositivo y la
            // sincronización lo subirá (compara por id, así que no duplica).
            // Antes se propagaba, y como TODOS los llamantes hacen `try?`, la
            // pantalla se cerraba como si se hubiera guardado: el entreno se
            // perdía sin que nada lo dijera.
            local.saveSession(session.toDTO())
        }
    }

    func deleteSession(id: String) async throws {
        if await isAuthenticated(), let uuid = UUID(uuidString: id) {
            do {
                try await remote.deleteSession(id: uuid)
            } catch {
                // 404 = no estaba en el servidor (se creó como invitado y nunca se
                // subió): borrarlo solo del dispositivo es lo correcto. Cualquier
                // otro error sí se propaga: si no, el borrado se daría por hecho y
                // el elemento reaparecería del servidor en la siguiente lectura.
                guard Self.isNotFound(error) else { throw error }
            }
        }
        // Borrar también en local: una copia local huérfana se contaría como
        // pendiente en la siguiente sincronización y se volvería a subir.
        local.deleteSession(id: id)
    }

    // MARK: Logs

    func getAllLogs() async throws -> [WorkoutLog] {
        let stored = local.getAllLogs().map { $0.toDomain() }
        guard await isAuthenticated() else { return stored }

        // Ver `getAllSessions`: fusión por id y degradación a local.
        let synced = (try? await remote.listLogs())?.map { $0.toDomain() } ?? []
        let syncedIds = Set(synced.map { $0.id })
        // Se ordena al mezclar (más reciente primero): concatenar dos fuentes
        // dejaba el historial descolocado para quien no ordena por su cuenta.
        return (synced + stored.filter { !syncedIds.contains($0.id) })
            .sorted { $0.startedAt > $1.startedAt }
    }

    func saveLog(_ log: WorkoutLog) async throws {
        guard await isAuthenticated() else {
            return local.saveLog(log.toDTO())
        }
        do {
            _ = try await remote.upsertLog(log)
        } catch {
            // Ver `saveSession`: un fallo del servidor no puede tragarse el
            // registro de un entreno que el usuario acaba de hacer.
            local.saveLog(log.toDTO())
        }
    }

    func deleteLog(id: String) async throws {
        if await isAuthenticated(), let uuid = UUID(uuidString: id) {
            do {
                try await remote.deleteLog(id: uuid)
            } catch {
                guard Self.isNotFound(error) else { throw error }
            }
        }
        // Ver deleteSession: sin esto la copia local resucita al sincronizar.
        local.deleteLog(id: id)
    }

    /// `true` si el servidor contestó 404. Se usa para distinguir "esto no existía
    /// en la cuenta" de "no he podido hablar con el servidor", que exigen lo
    /// contrario: borrar sin más, o no dar el borrado por hecho.
    private static func isNotFound(_ error: Error) -> Bool {
        if case NetworkError.failure(let statusCode, _, _) = error {
            return statusCode == 404
        }
        return false
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
