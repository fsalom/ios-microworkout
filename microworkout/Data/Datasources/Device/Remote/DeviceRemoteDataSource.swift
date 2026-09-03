import Foundation
import TripleA

protocol DeviceRemoteDataSourceProtocol {
    func register(token: String) async throws
    func remove(token: String) async throws
}

/// Habla con `/v1/devices` del backend FastAPI.
final class DeviceRemoteDataSource: DeviceRemoteDataSourceProtocol {
    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    /// Builds de debug reciben por el APNs de sandbox; sin decírselo al backend,
    /// el envío sería un `BadDeviceToken` silencioso.
    private static var isSandbox: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    func register(token: String) async throws {
        let endpoint = Endpoint(
            path: "v1/devices",
            httpMethod: .put,
            parameters: ["apns_token": token, "sandbox": Self.isSandbox]
        )
        let (status, _) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw DomainError.network(underlying: URLError(.badServerResponse)) }
    }

    func remove(token: String) async throws {
        let endpoint = Endpoint(
            path: "v1/devices/delete",
            httpMethod: .post,
            parameters: ["apns_token": token, "sandbox": Self.isSandbox]
        )
        let (status, _) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw DomainError.network(underlying: URLError(.badServerResponse)) }
    }
}
