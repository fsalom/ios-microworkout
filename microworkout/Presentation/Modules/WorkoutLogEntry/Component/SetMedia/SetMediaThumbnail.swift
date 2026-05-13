import AVFoundation
import ImageIO
import SwiftUI
import UIKit

/// In-memory cache of ready-to-play AVPlayerItems keyed by URL.
/// Lets us pay the cost of `asset.load(...)` ahead of time so the viewer
/// can start playing immediately when the user taps a video.
actor VideoPreloader {
    static let shared = VideoPreloader()

    private var cache: [URL: AVPlayerItem] = [:]
    private var inFlight: [URL: Task<AVPlayerItem, Never>] = [:]

    /// Ensure an item is loaded for `url`. Idempotent. Safe to await multiple times concurrently.
    @discardableResult
    func preload(_ url: URL) async -> AVPlayerItem {
        if let cached = cache[url] { return cached }
        if let task = inFlight[url] { return await task.value }

        let task = Task<AVPlayerItem, Never> {
            let asset = AVURLAsset(url: url, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: false,
            ])
            _ = try? await asset.load(.isPlayable, .tracks, .duration)
            let item = AVPlayerItem(asset: asset)
            item.preferredForwardBufferDuration = 1.5
            return item
        }
        inFlight[url] = task
        let item = await task.value
        cache[url] = item
        inFlight[url] = nil
        return item
    }

    /// Take ownership of the preloaded item (removed from cache). Returns nil if not preloaded.
    func consume(_ url: URL) -> AVPlayerItem? {
        let item = cache[url]
        cache[url] = nil
        return item
    }

    func clear() {
        cache.removeAll()
        inFlight.values.forEach { $0.cancel() }
        inFlight.removeAll()
    }
}

enum MediaImageLoader {
    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 60
        c.totalCostLimit = 64 * 1024 * 1024
        return c
    }()

    static func load(url: URL, maxPixelSize: CGFloat, scale: CGFloat = 1) async -> UIImage? {
        let pixelSize = max(64, Int((maxPixelSize * scale).rounded()))
        let key = "\(url.absoluteString)#\(pixelSize)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        return await Task.detached(priority: .userInitiated) { () -> UIImage? in
            let sourceOpts: [CFString: Any] = [kCGImageSourceShouldCache: false]
            guard let src = CGImageSourceCreateWithURL(url as CFURL, sourceOpts as CFDictionary) else {
                return nil
            }
            let thumbOpts: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: pixelSize,
            ]
            guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, thumbOpts as CFDictionary) else {
                return nil
            }
            let image = UIImage(cgImage: cg)
            cache.setObject(image, forKey: key, cost: cg.width * cg.height * 4)
            return image
        }.value
    }
}

