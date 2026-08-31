import Foundation

/// El informe vive en el servidor: es contexto para el coach, que también está en
/// el servidor. En modo invitado no hay dónde guardarlo, así que estos métodos
/// fallan con `DomainError.notAuthorized` y la UI lo explica.
protocol UserReportRepositoryProtocol {
    func getReport() async throws -> UserReport
    func setContent(_ content: String) async throws -> UserReport
    func deleteNote(id: Int) async throws
    /// Corrige el texto de una nota. El informe es del usuario: puede reescribir
    /// lo que el coach dedujo mal en vez de tener que borrarlo.
    func updateNote(id: Int, content: String) async throws
}
