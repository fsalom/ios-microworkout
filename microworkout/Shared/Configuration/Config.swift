import Foundation

class Config: ConfigTripleA {
    static let shared = Config()

    // Producción (backend desplegado). Para desarrollo local: "http://localhost:8002/"
    static let baseURL = "https://workout.fernandosalom.es/"
    static let scheme = "microworkout"
    static let appName = "microworkout"

    // MARK: API paths
    static let appleLoginPath = "v1/users/apple-login"
    static let googleLoginPath = "v1/users/google-login"
    static let refreshPath = "v1/users/refresh"
    static let logoutPath = "v1/users/logout"
    static let mePath = "v1/users/me"
}
