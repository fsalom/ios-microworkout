import Foundation
import TripleA

protocol AICoachRemoteDataSourceProtocol {
    /// Va emitiendo los trozos de texto del modelo a medida que llegan.
    /// El stream termina al recibir el centinela `[DONE]` del backend.
    func streamCoach(_ request: AICoachRequestApiDTO) -> AsyncThrowingStream<String, Error>
    /// Consejo compacto para una tarjeta. Sin streaming: se necesita entero.
    func insight(_ request: AICoachRequestApiDTO) async throws -> AIInsightApiDTO
}

/// Habla con `/v1/ai/coach` (SSE) y `/v1/ai/insight` (JSON) del backend FastAPI.
///
/// El chat no puede ir por `Network` de TripleA: sus `load*` esperan a tener el
/// body completo, y aquí lo que se quiere es justamente pintar mientras llega.
/// Así que el streaming usa `URLSession.bytes` directamente y solo le pide a
/// TripleA el access token (que es quien sabe refrescarlo). El endpoint de
/// insight sí pasa por `Network`, para heredar el manejo de sesión caducada.
final class AICoachRemoteDataSource: AICoachRemoteDataSourceProtocol {
    private let network: Network
    private let authenticator: AuthenticatorProtocol
    private let baseURL: String
    private let session: URLSession

    init(
        network: Network = Config.shared.network,
        authenticator: AuthenticatorProtocol = Config.shared.appAuthenticator,
        baseURL: String = Config.baseURL,
        session: URLSession = AICoachRemoteDataSource.makeStreamingSession()
    ) {
        self.network = network
        self.authenticator = authenticator
        self.baseURL = baseURL
        self.session = session
    }

    /// `timeoutIntervalForRequest` en un stream mide el hueco entre paquetes, no
    /// la duración total, así que 60 s de margen entre chunks es de sobra y a la
    /// vez evita quedarse colgado si el servidor deja de emitir.
    static func makeStreamingSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }

    // MARK: - Chat (SSE)

    func streamCoach(_ request: AICoachRequestApiDTO) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let urlRequest = try await self.makeStreamingRequest(
                        path: "v1/ai/coach",
                        body: request
                    )
                    let (bytes, response) = try await self.session.bytes(for: urlRequest)

                    if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                        throw Self.mapStatus(http.statusCode)
                    }

                    for try await line in bytes.lines {
                        // Un `event: error` va seguido de su `data:` con el detalle,
                        // así que basta con inspeccionar las líneas de datos.
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst("data:".count)
                            .trimmingCharacters(in: .whitespaces)

                        if payload == "[DONE]" {
                            continuation.finish()
                            return
                        }
                        guard let data = payload.data(using: .utf8) else { continue }
                        let chunk = try? JSONDecoder().decode(SSEChunk.self, from: data)
                        if let error = chunk?.error {
                            throw DomainError.network(underlying: AICoachStreamError(message: error))
                        }
                        if let text = chunk?.text, !text.isEmpty {
                            continuation.yield(text)
                        }
                    }
                    // El servidor cerró sin `[DONE]`: lo recibido sigue siendo válido.
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: DomainError.map(error))
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func makeStreamingRequest(
        path: String,
        body: AICoachRequestApiDTO
    ) async throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw DomainError.unknown(URLError(.badURL))
        }
        // `getCurrentToken` refresca si hace falta y lanza si la sesión ya no vale.
        let token: String
        do {
            token = try await authenticator.getCurrentToken()
        } catch {
            throw DomainError.notAuthorized
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // El MISMO idioma que va en el body. Antes aquí iba `Locale.current`, así
        // que cabecera y payload se contradecían: con el móvil en inglés el body
        // pedía "es" y la cabecera "en_US", y bastaba con que el backend mirara la
        // cabecera para que volviera el bug de contestar en inglés dentro de una
        // app en español.
        request.setValue(AICoachRequestApiDTO.appLanguage, forHTTPHeaderField: "Accept-Language")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    // MARK: - Insight (JSON)

    func insight(_ request: AICoachRequestApiDTO) async throws -> AIInsightApiDTO {
        let endpoint = Endpoint(
            path: "v1/ai/insight",
            httpMethod: .post,
            parameters: try Self.asParameters(request)
        )
        let (status, data) = try await network.loadAuthorized(this: endpoint)
        guard status < 400 else { throw Self.mapStatus(status) }
        guard let data else { throw DomainError.notFound }
        do {
            return try JSONDecoder().decode(AIInsightApiDTO.self, from: data)
        } catch {
            throw DomainError.decoding(underlying: error)
        }
    }

    /// `Endpoint` de TripleA serializa el body desde `[String: Any]`, así que hay
    /// que pasar por JSON para no duplicar el mapeo de claves a mano.
    private static func asParameters(_ request: AICoachRequestApiDTO) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DomainError.decoding(underlying: URLError(.cannotParseResponse))
        }
        return dictionary
    }

    private static func mapStatus(_ status: Int) -> DomainError {
        switch status {
        case 401, 403: return .notAuthorized
        case 404: return .notFound
        default:
            return .network(
                underlying: AICoachStreamError(message: "El servidor respondió \(status).")
            )
        }
    }

    private struct SSEChunk: Decodable {
        let text: String?
        let error: String?
    }
}

/// Error con el mensaje que manda el backend, para poder mostrarlo tal cual.
struct AICoachStreamError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
