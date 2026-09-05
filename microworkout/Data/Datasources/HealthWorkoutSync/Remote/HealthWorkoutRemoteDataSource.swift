import Foundation
import TripleA

protocol HealthWorkoutRemoteDataSourceProtocol {
    /// Ids (uuid de HKWorkout) que la cuenta ya tiene en la ventana dada.
    func syncedIds(from start: Date, to end: Date) async throws -> Set<String>
    /// Sube un lote. Devuelve cuántos escribió el servidor.
    func upsertMany(_ workouts: [HealthWorkout]) async throws -> Int
}

/// Habla con `/v1/health-workouts` del backend FastAPI.
final class HealthWorkoutRemoteDataSource: HealthWorkoutRemoteDataSourceProtocol {
    /// Tope del backend por petición.
    static let bulkChunkSize = 500

    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    func syncedIds(from start: Date, to end: Date) async throws -> Set<String> {
        let endpoint = Endpoint(
            path: "v1/health-workouts",
            httpMethod: .get,
            query: [
                "from": Self.day.string(from: start),
                "to": Self.day.string(from: end)
            ]
        )
        let (status, data) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw DomainError.network(underlying: URLError(.badServerResponse)) }
        guard let data else { return [] }
        struct Row: Decodable { let id: String }
        do {
            return Set(try JSONDecoder().decode([Row].self, from: data).map(\.id))
        } catch {
            throw DomainError.decoding(underlying: error)
        }
    }

    func upsertMany(_ workouts: [HealthWorkout]) async throws -> Int {
        var written = 0
        for chunk in workouts.chunked(into: Self.bulkChunkSize) {
            let endpoint = Endpoint(
                path: "v1/health-workouts",
                httpMethod: .put,
                parameters: ["workouts": chunk.map(Self.payload)]
            )
            let (status, _) = try await network.loadAuthorized(this: endpoint)
            guard status < 400 else { throw DomainError.network(underlying: URLError(.badServerResponse)) }
            written += chunk.count
        }
        return written
    }

    private static func payload(for workout: HealthWorkout) -> [String: Any] {
        var body: [String: Any] = [
            "id": workout.id,
            "activity_type_name": workout.activityTypeName,
            "started_at": iso.string(from: workout.startDate),
            "ended_at": iso.string(from: workout.endDate),
            "duration_seconds": workout.durationInSeconds
        ]
        if let calories = workout.totalCalories { body["total_calories"] = calories }
        if let distance = workout.totalDistance { body["total_distance"] = distance }
        if let heartRate = workout.averageHeartRate { body["average_heart_rate"] = heartRate }
        return body
    }

    private static let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
