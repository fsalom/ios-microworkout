import Foundation

protocol UserReportUseCaseProtocol {
    func getReport() async throws -> UserReport
    func save(content: String) async throws -> UserReport
    func deleteNote(id: Int) async throws
    func updateNote(id: Int, content: String) async throws
}

final class UserReportUseCase: UserReportUseCaseProtocol {
    /// Igual que el límite del backend (`max_length=4000`): recortar aquí evita un
    /// 422 después de que el usuario haya escrito.
    static let maxContentLength = 4_000

    private let repository: UserReportRepositoryProtocol

    init(repository: UserReportRepositoryProtocol) {
        self.repository = repository
    }

    func getReport() async throws -> UserReport {
        try await repository.getReport()
    }

    func save(content: String) async throws -> UserReport {
        let trimmed = String(
            content.trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(Self.maxContentLength)
        )
        return try await repository.setContent(trimmed)
    }

    func deleteNote(id: Int) async throws {
        try await repository.deleteNote(id: id)
    }

    func updateNote(id: Int, content: String) async throws {
        // Vacía no se manda: el backend la rechazaría (min_length=1), y la UI ya
        // desactiva guardar sin texto — esto es el cinturón además del tirante.
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try await repository.updateNote(id: id, content: String(trimmed.prefix(500)))
    }
}
