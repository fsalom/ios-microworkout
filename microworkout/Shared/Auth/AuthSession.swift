import Foundation
import Combine

enum AuthState: Equatable {
    case unknown
    case guest
    case authenticated(AuthenticatedUser)

    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }

    var user: AuthenticatedUser? {
        if case .authenticated(let user) = self { return user }
        return nil
    }
}

@MainActor
final class AuthSession: ObservableObject {
    static let shared = AuthSession()

    @Published private(set) var state: AuthState = .unknown

    private let userKey = "auth.user"
    private let userDefaults: UserDefaults

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func bootstrap() async {
        let isLogged = await Config.shared.appAuthenticator.isLogged()
        if isLogged, let user = loadUser() {
            state = .authenticated(user)
        } else {
            state = .guest
        }
    }

    func setAuthenticated(_ user: AuthenticatedUser) {
        saveUser(user)
        state = .authenticated(user)
    }

    func setGuest() {
        clearUser()
        state = .guest
    }

    // MARK: - User persistence

    private func loadUser() -> AuthenticatedUser? {
        guard let data = userDefaults.data(forKey: userKey) else { return nil }
        return try? JSONDecoder().decode(AuthenticatedUser.self, from: data)
    }

    private func saveUser(_ user: AuthenticatedUser) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        userDefaults.set(data, forKey: userKey)
    }

    private func clearUser() {
        userDefaults.removeObject(forKey: userKey)
    }
}
