import Foundation

final class DeviceRepository: DeviceRepositoryProtocol {
    private let remote: DeviceRemoteDataSourceProtocol
    private let session: AuthStateProviding

    init(
        remote: DeviceRemoteDataSourceProtocol,
        session: AuthStateProviding = SharedAuthState()
    ) {
        self.remote = remote
        self.session = session
    }

    func register(token: String) async throws {
        guard await session.isAuthenticated else { return }
        try await remote.register(token: token)
    }

    func remove(token: String) async throws {
        guard await session.isAuthenticated else { return }
        try await remote.remove(token: token)
    }
}
