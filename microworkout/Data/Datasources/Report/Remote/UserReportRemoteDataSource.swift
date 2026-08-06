import Foundation
import TripleA

protocol UserReportRemoteDataSourceProtocol {
    func get() async throws -> UserReportApiDTO
    func setContent(_ content: String) async throws -> UserReportApiDTO
    func deleteNote(id: Int) async throws
}

/// Habla con `/v1/profile/report` del backend FastAPI.
final class UserReportRemoteDataSource: UserReportRemoteDataSourceProtocol {
    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    func get() async throws -> UserReportApiDTO {
        let endpoint = Endpoint(path: "v1/profile/report", httpMethod: .get)
        return try await decode(endpoint)
    }

    func setContent(_ content: String) async throws -> UserReportApiDTO {
        let endpoint = Endpoint(
            path: "v1/profile/report",
            httpMethod: .put,
            parameters: ["content": content]
        )
        return try await decode(endpoint)
    }

    func deleteNote(id: Int) async throws {
        let endpoint = Endpoint(path: "v1/profile/report/notes/\(id)", httpMethod: .delete)
        let (status, _) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw Self.mapStatus(status) }
    }

    private func decode(_ endpoint: Endpoint) async throws -> UserReportApiDTO {
        let (status, data) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw Self.mapStatus(status) }
        guard let data else { throw DomainError.notFound }
        do {
            return try Self.decoder.decode(UserReportApiDTO.self, from: data)
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

    /// Internal (no privado) para que un test pueda fijar el contrato de fechas
    /// con el backend, que es donde más fácil se rompe.
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            // El backend serializa con microsegundos y, según el campo, con o sin
            // zona: se prueban las dos formas antes de fallar.
            if let date = UserReportRemoteDataSource.isoWithFraction.date(from: text) { return date }
            if let date = UserReportRemoteDataSource.iso.date(from: text) { return date }
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Fecha no válida: \(text)")
            )
        }
        return decoder
    }()

    private static let isoWithFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso = ISO8601DateFormatter()
}
