import Foundation
import UIKit

class SetMediaUseCase: SetMediaUseCaseProtocol {
    private let repository: SetMediaRepositoryProtocol

    init(repository: SetMediaRepositoryProtocol) {
        self.repository = repository
    }

    func addPhoto(setId: UUID, image: UIImage) async throws -> SetMedia {
        let media = try await repository.savePhoto(setId: setId, image: image)
        NotificationCenter.default.post(name: .setMediaChanged, object: setId)
        return media
    }

    func addVideo(setId: UUID, sourceURL: URL) async throws -> SetMedia {
        let media = try await repository.saveVideo(setId: setId, sourceURL: sourceURL)
        NotificationCenter.default.post(name: .setMediaChanged, object: setId)
        return media
    }

    func getMedia(forSetId setId: UUID) async throws -> [SetMedia] {
        try await repository.getMedia(forSetId: setId)
    }

    func delete(_ mediaId: UUID) async throws {
        let removed = try await repository.delete(mediaId)
        if let setId = removed?.setId {
            NotificationCenter.default.post(name: .setMediaChanged, object: setId)
        }
    }

    func fileURL(for media: SetMedia) -> URL {
        repository.fileURL(for: media)
    }

    func thumbnailURL(for media: SetMedia) -> URL? {
        repository.thumbnailURL(for: media)
    }
}
