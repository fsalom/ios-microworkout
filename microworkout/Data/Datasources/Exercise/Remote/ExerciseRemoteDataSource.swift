import Foundation
import TripleA

protocol ExerciseRemoteDataSourceProtocol {
    func list(contains search: String?) async throws -> [ExerciseApiDTO]
    func create(name: String, type: ExerciseType) async throws -> ExerciseApiDTO
    func delete(_ id: UUID) async throws
}

/// Talks to the FastAPI backend at `/v1/exercises`.
final class ExerciseRemoteDataSource: ExerciseRemoteDataSourceProtocol {
    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    func list(contains search: String?) async throws -> [ExerciseApiDTO] {
        var query: [String: Any] = [:]
        if let search, !search.isEmpty { query["q"] = search }
        let endpoint = Endpoint(path: "v1/exercises", httpMethod: .get, query: query)
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { return [] }
        return try JSONDecoder().decode([ExerciseApiDTO].self, from: data)
    }

    func create(name: String, type: ExerciseType) async throws -> ExerciseApiDTO {
        let body: [String: Any] = ["name": name, "type": type.rawValue]
        let endpoint = Endpoint(path: "v1/exercises", httpMethod: .post, parameters: body)
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { throw NetworkError.invalidResponse }
        return try JSONDecoder().decode(ExerciseApiDTO.self, from: data)
    }

    func delete(_ id: UUID) async throws {
        let endpoint = Endpoint(
            path: "v1/exercises/\(id.uuidString.lowercased())",
            httpMethod: .delete
        )
        _ = try await network.loadAuthorized(this: endpoint)
    }
}
