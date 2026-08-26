import Foundation
import TripleA

protocol CoachFeedbackRemoteDataSourceProtocol {
    func send(_ signal: CoachFeedbackSignal) async throws
}

/// Habla con `/v1/ai/feedback` del backend FastAPI.
final class CoachFeedbackRemoteDataSource: CoachFeedbackRemoteDataSourceProtocol {
    private let network: Network

    init(network: Network = Config.shared.network) {
        self.network = network
    }

    func send(_ signal: CoachFeedbackSignal) async throws {
        // El backend valida con `extra="forbid"` y limita `summary` a 200 y
        // `reason` a 500: se recorta aquí para que una señal larga no se convierta
        // en un 422 que la pierda entera.
        var parameters: [String: Any] = [
            "kind": signal.kind.rawValue,
            "verdict": signal.verdict.rawValue,
            "summary": String(signal.summary.prefix(200))
        ]
        if let topic = signal.topic { parameters["topic"] = topic.rawValue }
        if let reason = signal.reason, !reason.isEmpty {
            parameters["reason"] = String(reason.prefix(500))
        }

        let endpoint = Endpoint(path: "v1/ai/feedback", httpMethod: .post, parameters: parameters)
        let (status, _) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw DomainError.network(underlying: URLError(.badServerResponse)) }
    }
}
