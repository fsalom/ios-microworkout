import Foundation

/// Convierte SetMedia ↔ SetMediaDTO en la frontera con el datasource local.
class SetMediaRepository: SetMediaRepositoryProtocol {
    private let localDataSource: SetMediaDataSourceProtocol

    init(localDataSource: SetMediaDataSourceProtocol) {
        self.localDataSource = localDataSource
    }

    func savePhoto(setId: UUID, imageData: Data) async throws -> SetMedia {
        try await localDataSource.savePhoto(setId: setId, imageData: imageData).toDomain()
    }

    func saveVideo(setId: UUID, sourceURL: URL) async throws -> SetMedia {
        try await localDataSource.saveVideo(setId: setId, sourceURL: sourceURL).toDomain()
    }

    func getMedia(forSetId setId: UUID) async throws -> [SetMedia] {
        try await localDataSource.getMedia(forSetId: setId).map { $0.toDomain() }
    }

    @discardableResult
    func delete(_ mediaId: UUID) async throws -> SetMedia? {
        try await localDataSource.delete(mediaId)?.toDomain()
    }

    func fileURL(for media: SetMedia) -> URL {
        localDataSource.fileURL(for: media.toDTO())
    }

    func thumbnailURL(for media: SetMedia) -> URL? {
        localDataSource.thumbnailURL(for: media.toDTO())
    }
}
