import AVFoundation
import Foundation
import UIKit

class SetMediaLocalDataSource: SetMediaDataSourceProtocol {
    private let storage: UserDefaultsManagerProtocol
    private let fileManager: FileManager
    private let rootFolderName = "SetMedia"

    private enum Keys: String {
        case manifest = "set_media_v1"
    }

    init(storage: UserDefaultsManagerProtocol, fileManager: FileManager = .default) {
        self.storage = storage
        self.fileManager = fileManager
    }

    func savePhoto(setId: UUID, image: UIImage) async throws -> SetMedia {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "SetMedia", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo codificar la foto"])
        }
        let mediaId = UUID()
        let filename = "\(mediaId.uuidString).jpg"
        let folder = try ensureFolder(for: setId)
        let destination = folder.appendingPathComponent(filename)
        try data.write(to: destination, options: .atomic)

        let media = SetMedia(
            id: mediaId,
            setId: setId,
            type: .photo,
            filename: filename,
            createdAt: Date()
        )
        appendToManifest(media)
        return media
    }

    func saveVideo(setId: UUID, sourceURL: URL) async throws -> SetMedia {
        let mediaId = UUID()
        let ext = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
        let filename = "\(mediaId.uuidString).\(ext)"
        let folder = try ensureFolder(for: setId)
        let destination = folder.appendingPathComponent(filename)

        let needsStopAccess = sourceURL.startAccessingSecurityScopedResource()
        defer { if needsStopAccess { sourceURL.stopAccessingSecurityScopedResource() } }

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)

        let asset = AVURLAsset(url: destination)
        let duration = CMTimeGetSeconds(asset.duration)

        let thumbnailFilename = "\(mediaId.uuidString)_thumb.jpg"
        let thumbnailDestination = folder.appendingPathComponent(thumbnailFilename)
        let thumbnailGenerated = generateThumbnail(asset: asset, to: thumbnailDestination)

        let media = SetMedia(
            id: mediaId,
            setId: setId,
            type: .video,
            filename: filename,
            createdAt: Date(),
            durationSeconds: duration.isFinite ? duration : nil,
            thumbnailFilename: thumbnailGenerated ? thumbnailFilename : nil
        )
        appendToManifest(media)
        return media
    }

    func getMedia(forSetId setId: UUID) async throws -> [SetMedia] {
        let all: [SetMedia] = storage.get(forKey: Keys.manifest.rawValue) ?? []
        return all
            .filter { $0.setId == setId }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func delete(_ mediaId: UUID) async throws {
        var all: [SetMedia] = storage.get(forKey: Keys.manifest.rawValue) ?? []
        guard let media = all.first(where: { $0.id == mediaId }) else { return }
        let folder = folderURL(for: media.setId)
        let fileURL = folder.appendingPathComponent(media.filename)
        try? fileManager.removeItem(at: fileURL)
        if let thumbnail = media.thumbnailFilename {
            try? fileManager.removeItem(at: folder.appendingPathComponent(thumbnail))
        }
        all.removeAll { $0.id == mediaId }
        storage.save(all, forKey: Keys.manifest.rawValue)
    }

    func fileURL(for media: SetMedia) -> URL {
        folderURL(for: media.setId).appendingPathComponent(media.filename)
    }

    func thumbnailURL(for media: SetMedia) -> URL? {
        guard let thumbnail = media.thumbnailFilename else { return nil }
        return folderURL(for: media.setId).appendingPathComponent(thumbnail)
    }

    // MARK: - Helpers

    private func documentsURL() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func folderURL(for setId: UUID) -> URL {
        documentsURL()
            .appendingPathComponent(rootFolderName, isDirectory: true)
            .appendingPathComponent(setId.uuidString, isDirectory: true)
    }

    private func ensureFolder(for setId: UUID) throws -> URL {
        let folder = folderURL(for: setId)
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    private func appendToManifest(_ media: SetMedia) {
        var all: [SetMedia] = storage.get(forKey: Keys.manifest.rawValue) ?? []
        all.append(media)
        storage.save(all, forKey: Keys.manifest.rawValue)
    }

    private func generateThumbnail(asset: AVAsset, to destination: URL) -> Bool {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 600, height: 600)
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            guard let data = image.jpegData(compressionQuality: 0.7) else { return false }
            try data.write(to: destination, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
