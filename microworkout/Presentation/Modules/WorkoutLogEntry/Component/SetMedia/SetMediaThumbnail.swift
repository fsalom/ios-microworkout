import AVFoundation
import ImageIO
import SwiftUI
import UIKit

/// In-memory cache of pre-loaded AVURLAssets keyed by URL.
///
/// We cache the asset (not an AVPlayerItem) because AVPlayerItem can only belong
/// to a single AVPlayer at a time — sharing one between viewers/pages crashes with
/// "An AVPlayerItem cannot be associated with more than one instance of AVPlayer".
/// AVURLAsset, on the other hand, is freely shareable.
///
/// The asset is what's expensive to load (tracks, duration). By preloading it
/// ahead of time, opening the viewer just builds a cheap AVPlayerItem on top
/// and the first frame appears much sooner.
actor VideoPreloader {
    static let shared = VideoPreloader()

    private var cache: [URL: AVURLAsset] = [:]
    private var inFlight: [URL: Task<AVURLAsset, Never>] = [:]

    /// Ensures an asset is loaded for `url`. Idempotent and concurrency-safe.
    @discardableResult
    func preload(_ url: URL) async -> AVURLAsset {
        if let cached = cache[url] { return cached }
        if let task = inFlight[url] { return await task.value }

        let task = Task<AVURLAsset, Never> {
            let asset = AVURLAsset(url: url, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: false,
            ])
            _ = try? await asset.load(.tracks, .duration)
            return asset
        }
        inFlight[url] = task
        let asset = await task.value
        cache[url] = asset
        inFlight[url] = nil
        return asset
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

