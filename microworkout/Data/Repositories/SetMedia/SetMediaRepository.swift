import Foundation
import UIKit

class SetMediaRepository: SetMediaRepositoryProtocol {
    private let localDataSource: SetMediaDataSourceProtocol

    init(localDataSource: SetMediaDataSourceProtocol) {
        self.localDataSource = localDataSource
    }

    func savePhoto(setId: UUID, image: UIImage) async throws -> SetMedia {
        try await localDataSource.savePhoto(setId: setId, image: image)
    }

    func saveVideo(setId: UUID, sourceURL: URL) async throws -> SetMedia {
        try await localDataSource.saveVideo(setId: setId, sourceURL: sourceURL)
    }

    func getMedia(forSetId setId: UUID) async throws -> [SetMedia] {
        try await localDataSource.getMedia(forSetId: setId)
    }

    func delete(_ mediaId: UUID) async throws {
        try await localDataSource.delete(mediaId)
    }

    func fileURL(for media: SetMedia) -> URL {
        localDataSource.fileURL(for: media)
    }

    func thumbnailURL(for media: SetMedia) -> URL? {
        localDataSource.thumbnailURL(for: media)
    }
}
