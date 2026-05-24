import Foundation

protocol SetMediaUseCaseProtocol {
    func addPhoto(setId: UUID, imageData: Data) async throws -> SetMedia
    func addVideo(setId: UUID, sourceURL: URL) async throws -> SetMedia
    func getMedia(forSetId setId: UUID) async throws -> [SetMedia]
    func delete(_ mediaId: UUID) async throws
    func fileURL(for media: SetMedia) -> URL
    func thumbnailURL(for media: SetMedia) -> URL?
}
