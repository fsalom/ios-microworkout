import Foundation
import TripleA

protocol AuthServiceProtocol {
    func signInWithApple(authCode: String) async throws
    func signInWithGoogle(idToken: String) async throws
    func logout() async
}

enum AuthServiceError: Error, LocalizedError {
    case missingAuthorizationCode
    case backendUnavailable

    var errorDescription: String? {
        switch self {
        case .missingAuthorizationCode: return "No se obtuvo código de autorización de Apple"
        case .backendUnavailable: return "No se pudo contactar con el servidor"
        }
    }
}

final class AuthService: AuthServiceProtocol {
    private let appAuthenticator: AppAuthenticator
    private let network: Network
    private let session: AuthSession

    init(
        appAuthenticator: AppAuthenticator = Config.shared.appAuthenticator,
        network: Network = Config.shared.network,
        session: AuthSession = .shared
    ) {
        self.appAuthenticator = appAuthenticator
        self.network = network
        self.session = session
    }

    func signInWithApple(authCode: String) async throws {
        // La `card` de TripleA no aplica baseURL al endpoint (usa URLSession directo),
        // así que la URL debe ir completa en `path` o falla con "unsupported URL".
        let endpoint = Endpoint(
            path: Config.baseURL + Config.appleLoginPath,
            httpMethod: .post,
            parameters: ["auth_code": authCode],
            headers: ["Accept-Language": Locale.current.identifier]
        )
        try await appAuthenticator.getNewToken(with: ["auth_code": authCode], endpoint: endpoint)
        let me = try await network.loadAuthorized(
            this: Endpoint(path: Config.mePath, httpMethod: .get),
            of: AuthenticatedUser.self
        )
        await MainActor.run {
            session.setAuthenticated(me)
        }
    }

    /// Inicia sesión con Google. Recibe el `id_token` obtenido en el dispositivo
    /// (p.ej. del SDK GoogleSignIn) y sigue la misma secuencia que Apple:
    /// canjea tokens en el backend, carga /me y marca la sesión como autenticada.
    func signInWithGoogle(idToken: String) async throws {
        let endpoint = Endpoint(
            path: Config.baseURL + Config.googleLoginPath,
            httpMethod: .post,
            parameters: ["id_token": idToken],
            headers: ["Accept-Language": Locale.current.identifier]
        )
        try await appAuthenticator.getNewToken(with: ["id_token": idToken], endpoint: endpoint)
        let me = try await network.loadAuthorized(
            this: Endpoint(path: Config.mePath, httpMethod: .get),
            of: AuthenticatedUser.self
        )
        await MainActor.run {
            session.setAuthenticated(me)
        }
    }

    func logout() async {
        try? await appAuthenticator.logout()
        await MainActor.run {
            session.setGuest()
        }
    }
}
