import Foundation

/// A diferencia del resto de repositorios, este no tiene variante local: el
/// informe solo sirve para alimentar al coach, que corre en el servidor. Guardarlo
/// en el dispositivo daría la falsa impresión de que la IA lo está usando.
final class UserReportRepository: UserReportRepositoryProtocol {
    private let remote: UserReportRemoteDataSourceProtocol

    init(remote: UserReportRemoteDataSourceProtocol) {
        self.remote = remote
    }

    private func isAuthenticated() async -> Bool {
        await MainActor.run { AuthSession.shared.state.isAuthenticated }
    }

    func getReport() async throws -> UserReport {
        guard await isAuthenticated() else { throw DomainError.notAuthorized }
        return try await remote.get().toDomain()
    }

    func setContent(_ content: String) async throws -> UserReport {
        guard await isAuthenticated() else { throw DomainError.notAuthorized }
        return try await remote.setContent(content).toDomain()
    }

    func deleteNote(id: Int) async throws {
        guard await isAuthenticated() else { throw DomainError.notAuthorized }
        try await remote.deleteNote(id: id)
    }
}
