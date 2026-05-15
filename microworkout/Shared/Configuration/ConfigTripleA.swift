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
                return Endpoint(
                    path: Config.refreshPath,
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

    lazy var network = Network(
        baseURL: Config.baseURL,
        authenticator: appAuthenticator,
        format: .full
    )

    var authenticatedTestingEndpoint: TripleA.Endpoint? = Endpoint(
        path: Config.mePath,
        httpMethod: .get
    )
}
