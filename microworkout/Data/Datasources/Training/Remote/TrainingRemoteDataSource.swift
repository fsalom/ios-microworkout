import Foundation
import TripleA

protocol TrainingRemoteDataSourceProtocol {
    func list() async throws -> [TrainingApiDTO]
    func listFinished() async throws -> [TrainingApiDTO]
    func current() async throws -> TrainingApiDTO?
    func saveCurrent(_ training: Training) async throws -> TrainingApiDTO
    func finish(_ training: Training) async throws -> TrainingApiDTO
}

/// Talks to the FastAPI backend at `/v1/trainings`.
/// `saveCurrent` does PATCH-or-create: trains usually start from a local template
/// (UUID assigned client-side), so the first PATCH returns 404 and we POST.
final class TrainingRemoteDataSource: TrainingRemoteDataSourceProtocol {
    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    func list() async throws -> [TrainingApiDTO] {
        let endpoint = Endpoint(path: "v1/trainings", httpMethod: .get, query: ["status": "all"])
        return try await decodeList(endpoint)
    }

    func listFinished() async throws -> [TrainingApiDTO] {
        let endpoint = Endpoint(path: "v1/trainings", httpMethod: .get, query: ["status": "finished"])
        return try await decodeList(endpoint)
    }

    func current() async throws -> TrainingApiDTO? {
        let endpoint = Endpoint(path: "v1/trainings/current", httpMethod: .get)
        let (status, data) = try await network.loadAuthorized(this: endpoint)
        if status == 404 { return nil }
        guard let data else { throw NetworkError.invalidResponse }
        return try Self.decoder.decode(TrainingApiDTO.self, from: data)
    }

    func saveCurrent(_ training: Training) async throws -> TrainingApiDTO {
        let patchPayload = updatePayload(for: training, includeStartedAt: true)
        if let updated = try await patch(training.id, body: patchPayload) {
            return updated
        }
        return try await post(create: training, startedAt: training.startedAt ?? Date())
    }

    func finish(_ training: Training) async throws -> TrainingApiDTO {
        let payload = updatePayload(for: training, includeStartedAt: true, completedAt: training.completedAt ?? Date())
        if let updated = try await patch(training.id, body: payload) {
            return updated
        }
        // Training never existed on server — create it already completed.
        var created = try await post(create: training, startedAt: training.startedAt ?? Date())
        if let recovered = try await patch(created.id, body: payload) {
            created = recovered
        }
        return created
    }

    // MARK: - Helpers

    private func decodeList(_ endpoint: Endpoint) async throws -> [TrainingApiDTO] {
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { return [] }
        return try Self.decoder.decode([TrainingApiDTO].self, from: data)
    }

    private func patch(_ id: UUID, body: [String: Any]) async throws -> TrainingApiDTO? {
        let endpoint = Endpoint(
            path: "v1/trainings/\(id.uuidString.lowercased())",
            httpMethod: .patch,
            parameters: body
        )
        do {
            let (_, data) = try await network.loadAuthorized(this: endpoint)
            guard let data else { return nil }
            return try Self.decoder.decode(TrainingApiDTO.self, from: data)
        } catch let NetworkError.failure(statusCode, _, _) where statusCode == 404 {
            return nil
        }
    }

    private func post(create training: Training, startedAt: Date) async throws -> TrainingApiDTO {
        let body: [String: Any] = [
            "id": training.id.uuidString.lowercased(),
            "name": training.name,
            "image": training.image,
            "type": training.type.rawValue,
            "number_of_sets": training.numberOfSets,
            "number_of_reps": training.numberOfReps,
            "number_of_minutes_per_set": training.numberOfMinutesPerSet,
        ]
        let endpoint = Endpoint(path: "v1/trainings", httpMethod: .post, parameters: body)
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { throw NetworkError.invalidResponse }
        var created = try Self.decoder.decode(TrainingApiDTO.self, from: data)

        let patchBody = updatePayload(for: training, includeStartedAt: true)
        if let updated = try await patch(created.id, body: patchBody) {
            created = updated
        }
        return created
    }

    private func updatePayload(
        for training: Training,
        includeStartedAt: Bool,
        completedAt: Date? = nil
    ) -> [String: Any] {
        var payload: [String: Any] = [
            "sets": training.sets.map { Self.iso8601.string(from: $0) },
            "number_of_sets_completed": training.numberOfSetsCompleted,
            "number_of_seconds": training.numberOfSeconds,
        ]
        if includeStartedAt, let started = training.startedAt {
            payload["started_at"] = Self.iso8601.string(from: started)
        }
        if let completedAt {
            payload["completed_at"] = Self.iso8601.string(from: completedAt)
        }
        return payload
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
