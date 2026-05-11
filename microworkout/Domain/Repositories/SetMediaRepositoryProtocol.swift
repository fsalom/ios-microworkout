import Foundation
import UIKit

protocol SetMediaRepositoryProtocol {
    func savePhoto(setId: UUID, image: UIImage) async throws -> SetMedia
    func saveVideo(setId: UUID, sourceURL: URL) async throws -> SetMedia
    func getMedia(forSetId setId: UUID) async throws -> [SetMedia]
    func delete(_ mediaId: UUID) async throws
    func fileURL(for media: SetMedia) -> URL
    func thumbnailURL(for media: SetMedia) -> URL?
}
