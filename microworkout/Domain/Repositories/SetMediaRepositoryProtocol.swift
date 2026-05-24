import Foundation

protocol SetMediaRepositoryProtocol {
    func savePhoto(setId: UUID, imageData: Data) async throws -> SetMedia
    func saveVideo(setId: UUID, sourceURL: URL) async throws -> SetMedia
    func getMedia(forSetId setId: UUID) async throws -> [SetMedia]
    @discardableResult
    func delete(_ mediaId: UUID) async throws -> SetMedia?
    func fileURL(for media: SetMedia) -> URL
    func thumbnailURL(for media: SetMedia) -> URL?
}
