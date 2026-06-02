import Foundation
import TripleA

protocol WorkoutLogRemoteDataSourceProtocol {
    func listSessions() async throws -> [WorkoutSessionApiDTO]
    func upsertSession(_ session: WorkoutSession) async throws -> WorkoutSessionApiDTO
    func deleteSession(id: UUID) async throws

    func listLogs() async throws -> [WorkoutLogApiDTO]
    func upsertLog(_ log: WorkoutLog) async throws -> WorkoutLogApiDTO
    func deleteLog(id: UUID) async throws
}

/// Talks to `/v1/sessions` and `/v1/logs` on the FastAPI backend.
final class WorkoutLogRemoteDataSource: WorkoutLogRemoteDataSourceProtocol {
    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    // MARK: - Sessions

    func listSessions() async throws -> [WorkoutSessionApiDTO] {
        let endpoint = Endpoint(path: "v1/sessions", httpMethod: .get)
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { return [] }
        return try Self.decoder.decode([WorkoutSessionApiDTO].self, from: data)
    }

    func upsertSession(_ session: WorkoutSession) async throws -> WorkoutSessionApiDTO {
        let body: [String: Any] = [
            "name": session.name,
            "exercises": session.exercises.map { exercise in
                [
                    "exercise_id": exercise.id.uuidString.lowercased(),
                    "exercise_name": exercise.name,
                    "exercise_type": exercise.type.rawValue,
                ] as [String: Any]
            },
            "created_at": Self.iso8601.string(from: session.createdAt),
        ]
        let endpoint = Endpoint(
            path: "v1/sessions/\(session.id.uuidString.lowercased())",
            httpMethod: .put,
            parameters: body
        )
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { throw NetworkError.invalidResponse }
        return try Self.decoder.decode(WorkoutSessionApiDTO.self, from: data)
    }

    func deleteSession(id: UUID) async throws {
        let endpoint = Endpoint(
            path: "v1/sessions/\(id.uuidString.lowercased())",
            httpMethod: .delete
        )
        _ = try await network.loadAuthorized(this: endpoint)
    }

    // MARK: - Logs

    func listLogs() async throws -> [WorkoutLogApiDTO] {
        let endpoint = Endpoint(path: "v1/logs", httpMethod: .get)
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { return [] }
        return try Self.decoder.decode([WorkoutLogApiDTO].self, from: data)
    }

    func upsertLog(_ log: WorkoutLog) async throws -> WorkoutLogApiDTO {
        var body: [String: Any] = [
            "session_name": log.sessionName,
            "started_at": Self.iso8601.string(from: log.startedAt),
            "exercises": log.exercises.enumerated().map { _, exercise in
                exercisePayload(exercise)
            },
        ]
        if let sessionId = log.sessionId {
            body["session_id"] = sessionId.uuidString.lowercased()
        }
        if let endedAt = log.endedAt {
            body["ended_at"] = Self.iso8601.string(from: endedAt)
        }
        if let healthId = log.linkedHealthWorkoutId {
            body["linked_health_workout_id"] = healthId.uuidString
        }
        let endpoint = Endpoint(
            path: "v1/logs/\(log.id.uuidString.lowercased())",
            httpMethod: .put,
            parameters: body
        )
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { throw NetworkError.invalidResponse }
        return try Self.decoder.decode(WorkoutLogApiDTO.self, from: data)
    }

    func deleteLog(id: UUID) async throws {
        let endpoint = Endpoint(
            path: "v1/logs/\(id.uuidString.lowercased())",
            httpMethod: .delete
        )
        _ = try await network.loadAuthorized(this: endpoint)
    }

    // MARK: - Helpers

    private func exercisePayload(_ exercise: LoggedExercise) -> [String: Any] {
        var dict: [String: Any] = [
            "id": exercise.id.uuidString.lowercased(),
            "exercise_id": exercise.exercise.id.uuidString.lowercased(),
            "exercise_name": exercise.exercise.name,
            "exercise_type": exercise.exercise.type.rawValue,
            "sets": exercise.sets.map { setPayload($0) },
        ]
        if let notes = exercise.notes {
            dict["notes"] = notes
        }
        return dict
    }

    private func setPayload(_ loggedSet: LoggedSet) -> [String: Any] {
        var dict: [String: Any] = [
            "id": loggedSet.id.uuidString.lowercased(),
            "tags": loggedSet.tags.map { $0.rawValue },
        ]
        if let weight = loggedSet.weight { dict["weight"] = weight }
        if let reps = loggedSet.reps { dict["reps"] = reps }
        if let rir = loggedSet.rir { dict["rir"] = rir }
        return dict
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFraction.date(from: raw) { return date }
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let date = plain.date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognised date format: \(raw)"
            )
        }
        return d
    }()
}
