import AVFoundation
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

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
        let mediaId = UUID()
        let filename = "\(mediaId.uuidString).jpg"
        let folder = try ensureFolder(for: setId)
        let destination = folder.appendingPathComponent(filename)

        try await Task.detached(priority: .userInitiated) {
            try Self.writeCompressedJPEG(image: image, to: destination)
        }.value

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
        let filename = "\(mediaId.uuidString).mp4"
        let folder = try ensureFolder(for: setId)
        let destination = folder.appendingPathComponent(filename)
        let thumbnailFilename = "\(mediaId.uuidString)_thumb.jpg"
        let thumbnailDestination = folder.appendingPathComponent(thumbnailFilename)
        let fileManager = self.fileManager

        let result = try await Task.detached(priority: .userInitiated) { () -> (duration: Double?, hasThumbnail: Bool) in
            let needsStopAccess = sourceURL.startAccessingSecurityScopedResource()
            defer { if needsStopAccess { sourceURL.stopAccessingSecurityScopedResource() } }

            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }

            try await Self.exportCompressed(source: sourceURL, to: destination, fileManager: fileManager)

            let asset = AVURLAsset(url: destination)
            let cmDuration = try? await asset.load(.duration)
            let seconds = cmDuration.map { CMTimeGetSeconds($0) }
            let hasThumb = Self.generateThumbnail(asset: asset, to: thumbnailDestination)
            return (seconds?.isFinite == true ? seconds : nil, hasThumb)
        }.value

        let media = SetMedia(
            id: mediaId,
            setId: setId,
            type: .video,
            filename: filename,
            createdAt: Date(),
            durationSeconds: result.duration,
            thumbnailFilename: result.hasThumbnail ? thumbnailFilename : nil
        )
        appendToManifest(media)
        return media
    }

    fileprivate static func exportCompressed(source: URL, to destination: URL, fileManager: FileManager) async throws {
        let asset = AVURLAsset(url: source)
        let presets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        let preferred: [String] = [
            AVAssetExportPreset1280x720,
            AVAssetExportPresetMediumQuality,
            AVAssetExportPreset960x540,
        ]
        let preset = preferred.first(where: { presets.contains($0) }) ?? AVAssetExportPresetMediumQuality

        guard let exporter = AVAssetExportSession(asset: asset, presetName: preset) else {
            try fileManager.copyItem(at: source, to: destination)
            return
        }
        exporter.outputURL = destination
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true

        await exporter.export()

        if exporter.status != .completed {
            if fileManager.fileExists(atPath: destination.path) {
                try? fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: source, to: destination)
        }
    }

    func getMedia(forSetId setId: UUID) async throws -> [SetMedia] {
        let all: [SetMedia] = storage.get(forKey: Keys.manifest.rawValue) ?? []
        return all
            .filter { $0.setId == setId }
            .sorted { $0.createdAt < $1.createdAt }
    }

    @discardableResult
    func delete(_ mediaId: UUID) async throws -> SetMedia? {
        var all: [SetMedia] = storage.get(forKey: Keys.manifest.rawValue) ?? []
        guard let media = all.first(where: { $0.id == mediaId }) else { return nil }
        let folder = folderURL(for: media.setId)
        let fileURL = folder.appendingPathComponent(media.filename)
        try? fileManager.removeItem(at: fileURL)
        if let thumbnail = media.thumbnailFilename {
            try? fileManager.removeItem(at: folder.appendingPathComponent(thumbnail))
        }
        all.removeAll { $0.id == mediaId }
        storage.save(all, forKey: Keys.manifest.rawValue)
        return media
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

    fileprivate static func writeCompressedJPEG(image: UIImage, to destination: URL) throws {
        let maxPixel: CGFloat = 2048
        let quality: CGFloat = 0.8

        guard let cgImage = image.cgImage else {
            throw NSError(domain: "SetMedia", code: -1, userInfo: [NSLocalizedDescriptionKey: "Imagen inválida"])
        }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let largestSide = max(width, height)
        let scale = largestSide > maxPixel ? maxPixel / largestSide : 1
        let targetSize = CGSize(width: floor(width * scale), height: floor(height * scale))

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let oriented = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        let resized = renderer.image { _ in
            oriented.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let data = resized.jpegData(compressionQuality: quality) else {
            throw NSError(domain: "SetMedia", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo codificar la foto"])
        }
        try data.write(to: destination, options: .atomic)
    }

    fileprivate static func generateThumbnail(asset: AVAsset, to destination: URL) -> Bool {
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
