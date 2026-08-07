import Foundation
import TripleA

protocol BodyMetricsRemoteDataSourceProtocol {
    func list(from start: Date?, to end: Date?) async throws -> [DailyMetricsApiDTO]
    func upsert(_ measurement: DailyMetrics) async throws -> DailyMetricsApiDTO
    /// Sube varias de golpe. Devuelve cuántas escribió el servidor.
    func upsertMany(_ measurements: [DailyMetrics]) async throws -> Int
    func delete(date: Date) async throws
}

/// Habla con `/v1/profile/measurements` del backend FastAPI.
final class BodyMetricsRemoteDataSource: BodyMetricsRemoteDataSourceProtocol {
    /// Tope por petición del backend. Se trocea aquí para que quien llame no
    /// tenga que saberlo: la primera sincronización desde Salud puede traer años.
    static let bulkChunkSize = 400

    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    func list(from start: Date?, to end: Date?) async throws -> [DailyMetricsApiDTO] {
        var query: [String: Any] = [:]
        if let start { query["start"] = BodyMetricsDateFormat.day.string(from: start) }
        if let end { query["end"] = BodyMetricsDateFormat.day.string(from: end) }
        let endpoint = Endpoint(path: "v1/profile/measurements", httpMethod: .get, query: query)
        let (status, data) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw Self.mapStatus(status) }
        guard let data else { return [] }
        do {
            return try JSONDecoder().decode(MeasurementListApiDTO.self, from: data).measurements
        } catch {
            throw DomainError.decoding(underlying: error)
        }
    }

    func upsert(_ measurement: DailyMetrics) async throws -> DailyMetricsApiDTO {
        let endpoint = Endpoint(
            path: "v1/profile/measurements",
            httpMethod: .put,
            parameters: Self.payload(for: measurement)
        )
        let (status, data) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw Self.mapStatus(status) }
        guard let data else { throw DomainError.notFound }
        do {
            return try JSONDecoder().decode(DailyMetricsApiDTO.self, from: data)
        } catch {
            throw DomainError.decoding(underlying: error)
        }
    }

    func upsertMany(_ measurements: [DailyMetrics]) async throws -> Int {
        var written = 0
        for chunk in measurements.chunked(into: Self.bulkChunkSize) {
            let endpoint = Endpoint(
                path: "v1/profile/measurements/bulk",
                httpMethod: .post,
                parameters: ["measurements": chunk.map(Self.payload)]
            )
            let (status, _) = try await network.loadAuthorized(this: endpoint)
            guard status < 400 else { throw Self.mapStatus(status) }
            written += chunk.count
        }
        return written
    }

    func delete(date: Date) async throws {
        let day = BodyMetricsDateFormat.day.string(from: date)
        let endpoint = Endpoint(path: "v1/profile/measurements/\(day)", httpMethod: .delete)
        let (status, _) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw Self.mapStatus(status) }
    }

    private static func payload(for measurement: DailyMetrics) -> [String: Any] {
        var body: [String: Any] = [
            "date": BodyMetricsDateFormat.day.string(from: measurement.date),
            "source": measurement.source.rawValue,
        ]
        // El backend valida con `extra="forbid"` y rechaza null en campos con
        // rango: se omiten en vez de mandarse vacíos.
        if let weight = measurement.weightKg { body["weight_kg"] = weight }
        if let fat = measurement.bodyFatPercentage { body["body_fat_percentage"] = fat }
        if let steps = measurement.steps { body["steps"] = steps }
        if let kcal = measurement.activeKcal { body["active_kcal"] = kcal }
        if let minutes = measurement.exerciseMinutes { body["exercise_minutes"] = minutes }
        if let standing = measurement.standingMinutes { body["standing_minutes"] = standing }
        if let hr = measurement.restingHeartRate { body["resting_heart_rate"] = hr }
        return body
    }

    private static func mapStatus(_ status: Int) -> DomainError {
        switch status {
        case 401, 403: return .notAuthorized
        case 404: return .notFound
        default: return .network(underlying: URLError(.badServerResponse))
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
