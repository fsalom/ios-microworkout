import Foundation
import TripleA

protocol WeeklyPlanRemoteDataSourceProtocol {
    func get() async throws -> WeeklyPlanApiDTO
    func upsert(_ plan: WeeklyPlan) async throws -> WeeklyPlanApiDTO
}

/// Habla con `/v1/weekly-plan` del backend FastAPI.
final class WeeklyPlanRemoteDataSource: WeeklyPlanRemoteDataSourceProtocol {
    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    func get() async throws -> WeeklyPlanApiDTO {
        let endpoint = Endpoint(path: "v1/weekly-plan", httpMethod: .get)
        return try await decode(endpoint)
    }

    func upsert(_ plan: WeeklyPlan) async throws -> WeeklyPlanApiDTO {
        let endpoint = Endpoint(
            path: "v1/weekly-plan",
            httpMethod: .put,
            parameters: WeeklyPlanApiDTO.payload(for: plan)
        )
        return try await decode(endpoint)
    }

    private func decode(_ endpoint: Endpoint) async throws -> WeeklyPlanApiDTO {
        let (status, data) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw Self.mapStatus(status) }
        guard let data else { throw DomainError.notFound }
        do {
            return try JSONDecoder().decode(WeeklyPlanApiDTO.self, from: data)
        } catch {
            throw DomainError.decoding(underlying: error)
        }
    }

    private static func mapStatus(_ status: Int) -> DomainError {
        switch status {
        case 401, 403: return .notAuthorized
        case 404: return .notFound
        default: return .network(underlying: URLError(.badServerResponse))
        }
    }
}
