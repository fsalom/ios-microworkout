import Foundation

/// Trabaja con DTOs. Las URLs de fichero las devuelve el datasource porque
/// son responsabilidad de infraestructura, pero se construyen contra el DTO.
protocol SetMediaDataSourceProtocol {
    func savePhoto(setId: UUID, imageData: Data) async throws -> SetMediaDTO
    func saveVideo(setId: UUID, sourceURL: URL) async throws -> SetMediaDTO
    func getMedia(forSetId setId: UUID) async throws -> [SetMediaDTO]
    @discardableResult
    func delete(_ mediaId: UUID) async throws -> SetMediaDTO?
    func fileURL(for media: SetMediaDTO) -> URL
    func thumbnailURL(for media: SetMediaDTO) -> URL?
}
