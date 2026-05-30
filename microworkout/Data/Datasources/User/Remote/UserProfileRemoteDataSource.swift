import Foundation
import TripleA

protocol UserProfileRemoteDataSourceProtocol {
    func get() async throws -> UserProfileApiDTO?
    func upsert(_ profile: UserProfile) async throws -> UserProfileApiDTO
    func delete() async throws
}

/// Talks to `/v1/profile` on the FastAPI backend.
final class UserProfileRemoteDataSource: UserProfileRemoteDataSourceProtocol {
    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    func get() async throws -> UserProfileApiDTO? {
        let endpoint = Endpoint(path: "v1/profile", httpMethod: .get)
        do {
            let (status, data) = try await network.loadAuthorized(this: endpoint)
            if status == 404 { return nil }
            guard let data else { return nil }
            return try JSONDecoder().decode(UserProfileApiDTO.self, from: data)
        } catch let NetworkError.failure(statusCode, _, _) where statusCode == 404 {
            return nil
        }
    }

    func upsert(_ profile: UserProfile) async throws -> UserProfileApiDTO {
        let dto = UserProfileApiDTO.from(domain: profile)
        let body = try encodeForBody(dto)
        let endpoint = Endpoint(path: "v1/profile", httpMethod: .put, parameters: body)
        let (_, data) = try await network.loadAuthorized(this: endpoint)
        guard let data else { throw NetworkError.invalidResponse }
        return try JSONDecoder().decode(UserProfileApiDTO.self, from: data)
    }

    func delete() async throws {
        let endpoint = Endpoint(path: "v1/profile", httpMethod: .delete)
        _ = try await network.loadAuthorized(this: endpoint)
    }

    private func encodeForBody(_ dto: UserProfileApiDTO) throws -> [String: Any] {
        // TripleA's `parameters` expects [String: Any] and JSON-serializes it.
        // Round-trip through JSONEncoder/JSONSerialization to ensure correct
        // snake_case keys and `null` handling.
        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NetworkError.invalidResponse
        }
        return object
    }
}
