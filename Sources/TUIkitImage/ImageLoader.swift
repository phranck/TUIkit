//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageLoader.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum BoundedURLImageDataLoader {

    static func load(
        request: URLRequest,
        maxByteCount: Int,
        configuration: URLSessionConfiguration = .ephemeral
    ) throws -> Data {
        guard maxByteCount >= 0 else {
            throw ImageLoadError.inputTooLarge(byteCount: 0, limit: maxByteCount)
        }

        return try SessionDelegate(maxByteCount: maxByteCount).load(
            request: request,
            configuration: configuration
        )
    }
}

private extension BoundedURLImageDataLoader {

    final class SessionDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
        private let maxByteCount: Int
        private let completionSemaphore = DispatchSemaphore(value: 0)
        private let stateLock = NSLock()
        private var bufferedData = Data()
        private var result: Result<Data, Error>?

        init(maxByteCount: Int) {
            self.maxByteCount = maxByteCount
        }

        func load(request: URLRequest, configuration: URLSessionConfiguration) throws -> Data {
            let session = URLSession(
                configuration: configuration,
                delegate: self,
                delegateQueue: nil
            )
            let task = session.dataTask(with: request)
            task.resume()
            completionSemaphore.wait()
            session.invalidateAndCancel()

            stateLock.lock()
            let completedResult = result
            stateLock.unlock()

            guard let completedResult else {
                throw ImageLoadError.downloadFailed("Download finished without a result")
            }
            return try completedResult.get()
        }

        func urlSession(
            _ session: URLSession,
            dataTask: URLSessionDataTask,
            didReceive response: URLResponse,
            completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
        ) {
            let expectedByteCount = response.expectedContentLength
            if expectedByteCount > Int64(maxByteCount) {
                let reportedByteCount = min(expectedByteCount, Int64(Int.max))
                finish(
                    with: .failure(
                        ImageLoadError.inputTooLarge(
                            byteCount: Int(reportedByteCount),
                            limit: maxByteCount
                        )
                    )
                )
                completionHandler(.cancel)
                return
            }

            completionHandler(.allow)
        }

        func urlSession(
            _ session: URLSession,
            dataTask: URLSessionDataTask,
            didReceive data: Data
        ) {
            stateLock.lock()
            guard result == nil else {
                stateLock.unlock()
                dataTask.cancel()
                return
            }

            let remainingByteCount = maxByteCount - bufferedData.count
            guard data.count <= remainingByteCount else {
                let reportedByteCount = maxByteCount == Int.max ? Int.max : maxByteCount + 1
                result = .failure(
                    ImageLoadError.inputTooLarge(
                        byteCount: reportedByteCount,
                        limit: maxByteCount
                    )
                )
                stateLock.unlock()
                completionSemaphore.signal()
                dataTask.cancel()
                return
            }

            bufferedData.append(data)
            stateLock.unlock()
        }

        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            didCompleteWithError error: Error?
        ) {
            if let error {
                finish(with: .failure(error))
            } else {
                stateLock.lock()
                let data = bufferedData
                stateLock.unlock()
                finish(with: .success(data))
            }
        }

        private func finish(with completedResult: Result<Data, Error>) {
            stateLock.lock()
            guard result == nil else {
                stateLock.unlock()
                return
            }
            result = completedResult
            stateLock.unlock()
            completionSemaphore.signal()
        }
    }
}

// MARK: - ImageLoader Protocol

/// Loads images from file paths or raw data and converts them to `RGBAImage`.
///
/// Uses pure Swift decoders on all platforms for consistent behavior.
/// Supported formats: static PNG and JPEG, decoded as non-premultiplied 8-bit RGBA.
public protocol ImageLoader: Sendable {
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

    /// Loads an image from a file path with an optional pixel limit.
    func loadImage(from path: String, maxPixelCount: Int?) throws -> RGBAImage

    /// Loads an image from a URL using the supplied runtime cache.
    func loadImage(
        from urlString: String,
        cache: URLImageCache,
        timeout: TimeInterval,
        maxPixelCount: Int?
    ) throws -> RGBAImage
}

// MARK: - ImageLoader Defaults

public extension ImageLoader {
    func loadImage(from path: String, maxPixelCount: Int?) throws -> RGBAImage {
        let image = try loadImage(from: path)
        try validatePixelCount(image, maxPixelCount: maxPixelCount)
        return image
    }

    func loadImage(
        from urlString: String,
        cache: URLImageCache,
        timeout: TimeInterval,
        maxPixelCount: Int?
    ) throws -> RGBAImage {
        if let image = cache.get(urlString) {
            try validatePixelCount(image, maxPixelCount: maxPixelCount)
            return image
        }
        throw ImageLoadError.downloadFailed("URL loading is not supported by this image loader")
    }
}

// MARK: - ImageLoadError

/// Errors that can occur during image loading.
public enum ImageLoadError: Error, LocalizedError, CustomStringConvertible {
    /// The file was not found at the given path.
    case fileNotFound(String)

    /// The image format is not supported.
    case unsupportedFormat(String)

    /// The image data could not be decoded.
    case decodingFailed(String)

    /// A URL download failed.
    case downloadFailed(String)

    /// The image exceeds the maximum allowed pixel count.
    case imageTooLarge(pixelCount: Int, limit: Int)

    /// The encoded image exceeds the maximum allowed byte count.
    case inputTooLarge(byteCount: Int, limit: Int)

    /// An image dimension exceeds the maximum allowed size.
    case dimensionTooLarge(width: Int, height: Int, limit: Int)

    /// Image dimensions cannot be represented as a safe allocation size.
    case sizeOverflow(width: Int, height: Int)

    /// The final RGBA buffer would exceed its allocation limit.
    case allocationLimitExceeded(byteCount: Int, limit: Int)

    /// The decompressed source samples would exceed their byte limit.
    case decompressionLimitExceeded(byteCount: Int, limit: Int)

    /// The image contains more frames than the configured limit.
    case frameLimitExceeded(frameCount: Int, limit: Int)

    public var description: String {
        switch self {
        case .fileNotFound(let path):
            return "Image file not found: \(path)"
        case .unsupportedFormat(let format):
            return "Unsupported image format: \(format)"
        case .decodingFailed(let reason):
            return "Image decoding failed: \(reason)"
        case .downloadFailed(let reason):
            return "Image download failed: \(reason)"
        case .imageTooLarge(let pixelCount, let limit):
            return "Image too large: \(pixelCount) pixels (limit: \(limit))"
        case .inputTooLarge(let byteCount, let limit):
            return "Image input too large: \(byteCount) bytes (limit: \(limit))"
        case .dimensionTooLarge(let width, let height, let limit):
            return "Image dimensions too large: \(width)x\(height) (limit: \(limit))"
        case .sizeOverflow(let width, let height):
            return "Image dimensions overflow: \(width)x\(height)"
        case .allocationLimitExceeded(let byteCount, let limit):
            return "Image allocation too large: \(byteCount) bytes (limit: \(limit))"
        case .decompressionLimitExceeded(let byteCount, let limit):
            return "Image decompression too large: \(byteCount) bytes (limit: \(limit))"
        case .frameLimitExceeded(let frameCount, let limit):
            return "Image frame count too large: \(frameCount) frames (limit: \(limit))"
        }
    }

    public var errorDescription: String? { description }
}

// MARK: - Platform Image Loader

/// Cross-platform image loader backed by pure Swift PNG and JPEG decoders.
public struct PlatformImageLoader: ImageLoader {
    private let decoder: PureSwiftImageDecoder

    public init(limits: ImageDecodingLimits = .default) {
        decoder = PureSwiftImageDecoder(limits: limits)
    }

    public func loadImage(from path: String) throws -> RGBAImage {
        try loadImage(from: path, maxPixelCount: nil)
    }

    public func loadImage(from data: Data) throws -> RGBAImage {
        try loadImage(from: data, maxPixelCount: nil)
    }

    /// Loads an image from a file path with an optional pixel count limit.
    ///
    /// - Parameters:
    ///   - path: The absolute file path to the image.
    ///   - maxPixelCount: An optional tighter pixel limit. The loader-wide limit always applies.
    /// - Returns: The decoded image as `RGBAImage`.
    /// - Throws: `ImageLoadError` if the file cannot be read, decoded, or exceeds the limit.
    public func loadImage(from path: String, maxPixelCount: Int?) throws -> RGBAImage {
        guard FileManager.default.fileExists(atPath: path) else {
            throw ImageLoadError.fileNotFound(path)
        }

        let data = try readImageData(at: path)
        return try decoder.decode(data, maxPixelCount: maxPixelCount)
    }

    /// Loads an image from raw data with an optional pixel count limit.
    ///
    /// - Parameters:
    ///   - data: The image file data.
    ///   - maxPixelCount: An optional tighter pixel limit. The loader-wide limit always applies.
    /// - Returns: The decoded image as `RGBAImage`.
    /// - Throws: `ImageLoadError` if the data cannot be decoded or exceeds the limit.
    public func loadImage(from data: Data, maxPixelCount: Int?) throws -> RGBAImage {
        try decoder.decode(data, maxPixelCount: maxPixelCount)
    }
}

private extension PlatformImageLoader {

    func readImageData(at path: String) throws -> Data {
        let limit = decoder.maxInputBytes
        guard limit >= 0 else {
            throw ImageLoadError.inputTooLarge(byteCount: 0, limit: limit)
        }

        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
        } catch {
            throw ImageLoadError.decodingFailed("unable to read image file")
        }
        defer { try? handle.close() }

        var data = Data()
        do {
            while data.count <= limit {
                let remainingByteCount = limit == Int.max ? Int.max - data.count : limit + 1 - data.count
                let readByteCount = min(remainingByteCount, 64 * 1_024)
                guard readByteCount > 0,
                      let chunk = try handle.read(upToCount: readByteCount),
                      !chunk.isEmpty
                else {
                    break
                }
                data.append(chunk)
            }
        } catch {
            throw ImageLoadError.decodingFailed("unable to read image file")
        }

        guard data.count <= limit else {
            throw ImageLoadError.inputTooLarge(byteCount: data.count, limit: limit)
        }
        return data
    }
}

// MARK: - URL Image Cache

/// A session-scoped cache for images downloaded from URLs.
///
/// Cached entries persist for the lifetime of the application.
/// Thread-safe via an internal lock.
public final class URLImageCache: @unchecked Sendable {
    private var cache: [String: RGBAImage] = [:]
    private let lock = NSLock()

    /// Creates an empty session cache.
    public init() {}

    /// Returns a cached image for the given URL string, or nil.
    public func get(_ urlString: String) -> RGBAImage? {
        lock.lock()
        defer { lock.unlock() }
        return cache[urlString]
    }

    /// Stores an image in the cache for the given URL string.
    public func set(_ urlString: String, image: RGBAImage) {
        lock.lock()
        defer { lock.unlock() }
        cache[urlString] = image
    }

    /// Removes every cached image.
    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}

// MARK: - URL Image Loading

extension PlatformImageLoader {

    /// Loads an image from a URL, using the session cache.
    ///
    /// On first access the image is downloaded synchronously and cached.
    /// Subsequent calls for the same URL return the cached copy.
    ///
    /// - Parameters:
    ///   - urlString: The URL to download.
    ///   - cache: The image cache to use.
    ///   - timeout: The download timeout in seconds (default: 30).
    ///   - maxPixelCount: An optional tighter pixel limit. The loader-wide limit always applies.
    /// - Returns: The decoded image.
    /// - Throws: `ImageLoadError` on network or decoding failure, or if image exceeds size limit.
    public func loadImage(
        from urlString: String,
        cache: URLImageCache,
        timeout: TimeInterval = 30,
        maxPixelCount: Int? = nil
    ) throws -> RGBAImage {
        if let cached = cache.get(urlString) {
            try decoder.validateCachedImage(cached, maxPixelCount: maxPixelCount)
            return cached
        }

        guard let url = URL(string: urlString) else {
            throw ImageLoadError.downloadFailed("Invalid URL: \(urlString)")
        }

        let data: Data
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = timeout
            data = try BoundedURLImageDataLoader.load(
                request: request,
                maxByteCount: decoder.maxInputBytes
            )
        } catch let error as ImageLoadError {
            throw error
        } catch {
            throw ImageLoadError.downloadFailed(error.localizedDescription)
        }

        let image = try loadImage(from: data, maxPixelCount: maxPixelCount)
        cache.set(urlString, image: image)
        return image
    }
}

// MARK: - Pixel Limit Validation

private func validatePixelCount(_ image: RGBAImage, maxPixelCount: Int?) throws {
    guard let maxPixelCount else { return }
    let (pixelCount, overflow) = image.width.multipliedReportingOverflow(by: image.height)
    guard !overflow else {
        throw ImageLoadError.sizeOverflow(width: image.width, height: image.height)
    }
    guard pixelCount <= maxPixelCount else {
        throw ImageLoadError.imageTooLarge(pixelCount: pixelCount, limit: maxPixelCount)
    }
}
