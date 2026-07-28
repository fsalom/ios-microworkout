import Foundation
import TripleA

class ConfigTripleA: TripleAForSwiftUIProtocol {
    enum AuthAPI {
        case appleLogin
        case refresh

        var endpoint: Endpoint {
            switch self {
            case .appleLogin:
                return Endpoint(
                    path: Config.appleLoginPath,
                    httpMethod: .post,
                    headers: ["Accept-Language": Locale.current.identifier]
                )
            case .refresh:
                // La `card` de TripleA refresca con URLSession directo y NO
                // aplica baseURL, así que la URL debe ir completa aquí (igual que
                // en el login de AuthService). Con la ruta relativa fallaba con
                // "unsupported URL" y acababa borrando los tokens (refreshFailed).
                return Endpoint(
                    path: Config.baseURL + Config.refreshPath,
                    httpMethod: .post
                )
            }
        }
    }

    var storage: TokenStorageProtocol = AuthTokenStoreKeychain()

    var card: AuthenticationCardProtocol = OAuthGrantTypePasswordManager(
        refreshTokenEndpoint: AuthAPI.refresh.endpoint,
        tokensEndpoint: AuthAPI.appleLogin.endpoint
    )

    lazy var appAuthenticator = AppAuthenticator(
        storage: storage,
        card: card
    )

    lazy var authenticator: AuthenticatorSUI = .init(authenticator: appAuthenticator)

    lazy var network: Network = SessionAwareNetwork(
        baseURL: Config.baseURL,
        authenticator: appAuthenticator,
        format: .full
    )

    var authenticatedTestingEndpoint: TripleA.Endpoint? = Endpoint(
        path: Config.mePath,
        httpMethod: .get
    )
}

/// `Network` de TripleA con detección centralizada de sesión caducada.
///
/// Toda la autenticación pasa por TripleA; cuando el refresh del token falla el
/// SDK lanza un `AuthError`. Aquí lo interceptamos en un único punto para pasar
/// la sesión a invitado, de modo que la UI muestre el login en vez de una cuenta
/// "vinculada" que no funciona y en vez de reintentar el refresh en bucle.
final class SessionAwareNetwork: Network {
    override func loadAuthorized<T: Decodable>(this endpoint: Endpoint, of type: T.Type?) async throws -> T {
        do {
            return try await super.loadAuthorized(this: endpoint, of: type)
        } catch {
            await Self.handleSessionExpiry(error)
            throw error
        }
    }

    override func loadAuthorized(this endpoint: Endpoint) async throws -> (Int, Data?) {
        do {
            return try await super.loadAuthorized(this: endpoint)
        } catch {
            await Self.handleSessionExpiry(error)
            throw error
        }
    }

    private static func handleSessionExpiry(_ error: Error) async {
        guard isSessionExpired(error) else { return }
        await MainActor.run { AuthSession.shared.setGuest() }
    }
}

/// True si el error indica sesión inválida (token muerto/rechazado), no un fallo
/// transitorio de red. Vive en infra porque conoce los tipos de error de TripleA
/// (el SDK de auth) — el dominio y la presentación NO deben clasificar esto.
///
/// OJO: `Network.authorize` de TripleA captura el fallo de refresh, hace logout
/// interno y RE-LANZA `NetworkError.invalidToken` — así que el error que llega a
/// la app suele ser `NetworkError`, no `AuthError`. Ambos deben contar.
func isSessionExpired(_ error: Error) -> Bool {
    if let authError = error as? AuthError {
        switch authError {
        case .refreshFailed, .tokenNotFound, .missingToken, .notAuthorized:
            return true
        default:
            return false
        }
    }
    if let networkError = error as? NetworkError {
        switch networkError {
        case .invalidToken, .missingToken:
            return true
        default:
            return false
        }
    }
    return false
}
