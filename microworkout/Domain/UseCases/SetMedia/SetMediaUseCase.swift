import Foundation
import UIKit

class SetMediaUseCase: SetMediaUseCaseProtocol {
    private let repository: SetMediaRepositoryProtocol

    init(repository: SetMediaRepositoryProtocol) {
        self.repository = repository
    }

    func addPhoto(setId: UUID, image: UIImage) async throws -> SetMedia {
        try await repository.savePhoto(setId: setId, image: image)
    }

    func addVideo(setId: UUID, sourceURL: URL) async throws -> SetMedia {
        try await repository.saveVideo(setId: setId, sourceURL: sourceURL)
    }

    func getMedia(forSetId setId: UUID) async throws -> [SetMedia] {
        try await repository.getMedia(forSetId: setId)
    }

    func delete(_ mediaId: UUID) async throws {
        try await repository.delete(mediaId)
    }

    func fileURL(for media: SetMedia) -> URL {
        repository.fileURL(for: media)
    }

    func thumbnailURL(for media: SetMedia) -> URL? {
        repository.thumbnailURL(for: media)
    }
}
