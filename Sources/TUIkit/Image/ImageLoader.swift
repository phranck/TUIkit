//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageLoader.swift
//
//  Created by LAYERED.work
//  License: MIT

import CSTBImage
import Foundation

// MARK: - ImageLoader Protocol

/// Loads images from file paths or raw data and converts them to `RGBAImage`.
///
/// Uses stb_image (bundled C library) on all platforms for consistent behavior.
/// Supported formats: PNG, JPEG, GIF, BMP, TGA, HDR, PSD, PNM.
protocol ImageLoader: Sendable {
    /// Loads an image from a file path.
    ///
    /// - Parameter path: The absolute file path to the image.
    /// - Returns: The decoded image as `RGBAImage`.
    /// - Throws: `ImageLoadError` if the file cannot be read or decoded.
    func loadImage(from path: String) throws -> RGBAImage

    /// Loads an image from raw data.
    ///
    /// - Parameter data: The image file data.
    /// - Returns: The decoded image as `RGBAImage`.
    /// - Throws: `ImageLoadError` if the data cannot be decoded.
    func loadImage(from data: Data) throws -> RGBAImage
}

// MARK: - ImageLoadError

/// Errors that can occur during image loading.
enum ImageLoadError: Error, LocalizedError, CustomStringConvertible {
    /// The file was not found at the given path.
    case fileNotFound(String)

    /// The image format is not supported.
    case unsupportedFormat(String)

    /// The image data could not be decoded.
    case decodingFailed(String)

    /// A URL download failed.
    case downloadFailed(String)

    var description: String {
        switch self {
        case .fileNotFound(let path):
            return "Image file not found: \(path)"
        case .unsupportedFormat(let format):
            return "Unsupported image format: \(format)"
        case .decodingFailed(let reason):
            return "Image decoding failed: \(reason)"
        case .downloadFailed(let reason):
            return "Image download failed: \(reason)"
        }
    }

    var errorDescription: String? { description }
}

// MARK: - Platform Image Loader

/// Cross-platform image loader using stb_image.
///
/// Supports PNG, JPEG, GIF, BMP, TGA, HDR, PSD, and PNM formats
/// on both macOS and Linux. stb_image is a public-domain single-header
/// C library bundled as a local `CSTBImage` target.
struct PlatformImageLoader: ImageLoader {

    func loadImage(from path: String) throws -> RGBAImage {
        guard FileManager.default.fileExists(atPath: path) else {
            throw ImageLoadError.fileNotFound(path)
        }

        var width: Int32 = 0
        var height: Int32 = 0
        var channels: Int32 = 0

        guard let rawPixels = stbi_load(path, &width, &height, &channels, 4) else {
            let reason = String(cString: stbi_failure_reason())
            throw ImageLoadError.decodingFailed("stb_image: \(reason)")
        }
        defer { stbi_image_free(rawPixels) }

        return pixelsFromRaw(rawPixels, width: Int(width), height: Int(height))
    }

    func loadImage(from data: Data) throws -> RGBAImage {
        var width: Int32 = 0
        var height: Int32 = 0
        var channels: Int32 = 0

        let rawPixels: UnsafeMutablePointer<UInt8>? = data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return nil }
            return stbi_load_from_memory(
                baseAddress.assumingMemoryBound(to: UInt8.self),
                Int32(data.count),
                &width,
                &height,
                &channels,
                4
            )
        }

        guard let pixels = rawPixels else {
            let reason = String(cString: stbi_failure_reason())
            throw ImageLoadError.decodingFailed("stb_image: \(reason)")
        }
        defer { stbi_image_free(pixels) }

        return pixelsFromRaw(pixels, width: Int(width), height: Int(height))
    }
}

// MARK: - Private Helpers

extension PlatformImageLoader {

    /// Converts raw stb_image RGBA output to an `RGBAImage`.
    private func pixelsFromRaw(
        _ rawPixels: UnsafeMutablePointer<UInt8>,
        width: Int,
        height: Int
    ) -> RGBAImage {
        let count = width * height
        var pixels = [RGBA](repeating: RGBA(r: 0, g: 0, b: 0), count: count)

        for pixelIndex in 0..<count {
            let offset = pixelIndex * 4
            pixels[pixelIndex] = RGBA(
                r: rawPixels[offset],
                g: rawPixels[offset + 1],
                b: rawPixels[offset + 2],
                a: rawPixels[offset + 3]
            )
        }

        return RGBAImage(width: width, height: height, pixels: pixels)
    }
}

// MARK: - URL Image Cache

/// A session-scoped cache for images downloaded from URLs.
///
/// Cached entries persist for the lifetime of the application.
/// Thread-safe via an internal lock.
final class URLImageCache: @unchecked Sendable {
    /// Shared session cache.
    static let shared = URLImageCache()

    private var cache: [String: RGBAImage] = [:]
    private let lock = NSLock()

    private init() {}

    /// Returns a cached image for the given URL string, or nil.
    func get(_ urlString: String) -> RGBAImage? {
        lock.lock()
        defer { lock.unlock() }
        return cache[urlString]
    }

    /// Stores an image in the cache for the given URL string.
    func set(_ urlString: String, image: RGBAImage) {
        lock.lock()
        defer { lock.unlock() }
        cache[urlString] = image
    }
}

// MARK: - URL Image Loading

extension PlatformImageLoader {

    /// Loads an image from a URL, using the session cache.
    ///
    /// On first access the image is downloaded synchronously and cached.
    /// Subsequent calls for the same URL return the cached copy.
    ///
    /// - Parameter urlString: The URL to download.
    /// - Returns: The decoded image.
    /// - Throws: `ImageLoadError` on network or decoding failure.
    func loadImage(from urlString: String, cache: URLImageCache = .shared) throws -> RGBAImage {
        if let cached = cache.get(urlString) {
            return cached
        }

        guard let url = URL(string: urlString) else {
            throw ImageLoadError.downloadFailed("Invalid URL: \(urlString)")
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImageLoadError.downloadFailed(error.localizedDescription)
        }

        let image = try loadImage(from: data)
        cache.set(urlString, image: image)
        return image
    }
}
