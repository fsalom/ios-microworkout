import Foundation
import TripleA

protocol WorkoutEntryRemoteDataSourceProtocol {
    func syncedIds() async throws -> Set<UUID>
    func upsertMany(_ entries: [WorkoutEntry]) async throws -> Int
    func delete(entryID: UUID) async throws
}

/// Habla con `/v1/workout-entries` del backend FastAPI.
final class WorkoutEntryRemoteDataSource: WorkoutEntryRemoteDataSourceProtocol {
    static let bulkChunkSize = 500

    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    func syncedIds() async throws -> Set<UUID> {
        let endpoint = Endpoint(path: "v1/workout-entries", httpMethod: .get)
        let (status, data) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw DomainError.network(underlying: URLError(.badServerResponse)) }
        guard let data else { return [] }
        struct Row: Decodable { let id: UUID }
        do {
            return Set(try JSONDecoder().decode([Row].self, from: data).map(\.id))
        } catch {
            throw DomainError.decoding(underlying: error)
        }
    }

    func upsertMany(_ entries: [WorkoutEntry]) async throws -> Int {
        var written = 0
        for chunk in entries.chunked(into: Self.bulkChunkSize) {
            let endpoint = Endpoint(
                path: "v1/workout-entries",
                httpMethod: .put,
                parameters: ["entries": chunk.map(Self.payload)]
            )
            let (status, _) = try await network.loadAuthorized(this: endpoint)
            guard status < 400 else { throw DomainError.network(underlying: URLError(.badServerResponse)) }
            written += chunk.count
        }
        return written
    }

    func delete(entryID: UUID) async throws {
        let endpoint = Endpoint(path: "v1/workout-entries/\(entryID.uuidString)", httpMethod: .delete)
        let (status, _) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw DomainError.network(underlying: URLError(.badServerResponse)) }
    }

    private static func payload(for entry: WorkoutEntry) -> [String: Any] {
        var body: [String: Any] = [
            "id": entry.id.uuidString,
            "exercise_id": entry.exercise.id.uuidString,
            "exercise_name": entry.exercise.name,
            "exercise_type": entry.exercise.type.rawValue,
            "date": iso.string(from: entry.date),
            "is_completed": entry.isCompleted
        ]
        if let reps = entry.reps { body["reps"] = reps }
        if let weight = entry.weight { body["weight"] = weight }
        if let distance = entry.distanceMeters { body["distance_meters"] = distance }
        if let calories = entry.calories { body["calories"] = calories }
        return body
    }

    private static let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
