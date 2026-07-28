import Foundation
import UIKit
import TripleA
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

protocol AuthServiceProtocol {
    func signInWithApple(authCode: String) async throws
    /// Ejecuta el flujo nativo de Google (presentación + id_token) y lo canjea en
    /// el backend. El SDK queda encapsulado aquí; la capa de presentación no lo conoce.
    func signInWithGoogle() async throws
    func logout() async
    /// Entrega a Google el callback OAuth (`.onOpenURL`). Devuelve si lo gestionó.
    @discardableResult func handleOpenURL(_ url: URL) -> Bool
}

enum AuthServiceError: Error, LocalizedError {
    case missingAuthorizationCode
    case backendUnavailable
    case cancelled
    case googleUnavailable

    var errorDescription: String? {
        switch self {
        case .missingAuthorizationCode: return "No se obtuvo código de autorización de Apple"
        case .backendUnavailable: return "No se pudo contactar con el servidor"
        case .cancelled: return nil
        case .googleUnavailable: return "Inicio de sesión con Google no disponible"
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

    /// Inicia sesión con Google: presenta el flujo nativo, obtiene el `id_token`,
    /// lo canjea en el backend, carga /me y marca la sesión como autenticada.
    /// Todo el SDK de Google vive aquí (infra), no en la capa de presentación.
    func signInWithGoogle() async throws {
        #if canImport(GoogleSignIn)
        let idToken = try await Self.googleIdToken()
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
        #else
        throw AuthServiceError.googleUnavailable
        #endif
    }

    func logout() async {
        try? await appAuthenticator.logout()
        await MainActor.run {
            session.setGuest()
        }
    }

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        #if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.handle(url)
        #else
        return false
        #endif
    }

    #if canImport(GoogleSignIn)
    /// Lanza el flujo nativo de Google Sign-In y devuelve el `id_token`.
    /// Traduce la cancelación del usuario a `AuthServiceError.cancelled`.
    @MainActor
    private static func googleIdToken() async throws -> String {
        guard let presenter = topViewController() else {
            throw AuthServiceError.googleUnavailable
        }
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthServiceError.missingAuthorizationCode
            }
            return idToken
        } catch let ns as NSError where ns.domain == kGIDSignInErrorDomain
            && ns.code == GIDSignInError.canceled.rawValue {
            throw AuthServiceError.cancelled
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
    #endif
}
