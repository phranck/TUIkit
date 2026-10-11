//  🖥️ TUIKit — Terminal UI Kit for Swift
//  URLImageCoordinator.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - URL Image Data Transport

/// Fetches raw bytes for a URL request.
///
/// Split out from the coordinator so tests can inject scripted responses
/// without touching the network. Production uses `URLSessionImageTransport`.
protocol URLImageDataTransport: Sendable {
    /// Fetches the response bytes for the given request.
    ///
    /// - Parameter request: The request to perform. `timeoutInterval`
    ///   already reflects the caller's timeout.
    /// - Returns: The response bytes and the HTTP metadata.
    /// - Throws: Any error the transport encountered (surfaces cancellation
    ///   through `CancellationError` or `URLError.cancelled`).
    func fetch(request: URLRequest) async throws -> (Data, URLResponse)
}

/// Default transport backed by `URLSession.data(for:)`.
///
/// Uses one ephemeral session per instance so cookies and disk caches do
/// not bleed across runtimes.
struct URLSessionImageTransport: URLImageDataTransport {
    /// The session performing the requests.
    private let session: URLSession

    /// Creates a transport with the given session configuration.
    init(configuration: URLSessionConfiguration = .ephemeral) {
        self.session = URLSession(configuration: configuration)
    }

    func fetch(request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

// MARK: - URL Image Coordinator

/// Coordinates URL image loads: deduplicates identical in-flight requests,
/// enforces byte and status limits, and delegates decoding to the shared
/// pure Swift decoder.
///
/// Actor isolation guarantees that dedup bookkeeping and coordinator state
/// stay consistent under concurrent load without semaphores or unsafe
/// cross-actor result variables.
actor URLImageCoordinator {
    /// One in-flight download shared between deduplicated callers.
    private struct InFlight {
        let task: Task<RGBAImage, Error>
    }

    /// The transport performing the actual network requests.
    private let transport: any URLImageDataTransport

    /// In-flight downloads keyed by their URL string.
    private var inFlight: [String: InFlight] = [:]

    /// Creates a coordinator with the given transport.
    ///
    /// - Parameter transport: The transport that fetches URL bytes.
    ///   Defaults to `URLSessionImageTransport`.
    init(transport: any URLImageDataTransport = URLSessionImageTransport()) {
        self.transport = transport
    }

    /// Loads and decodes an image for the given URL.
    ///
    /// Cache hits skip the transport. Concurrent cache-missing loads for
    /// the same URL share a single transport call. A cancelled caller
    /// cancels the shared task only when no other caller is still waiting.
    ///
    /// - Parameters:
    ///   - urlString: The URL to load.
    ///   - cache: The runtime-owned image cache.
    ///   - timeout: The download timeout in seconds.
    ///   - maxPixelCount: An optional additional per-image pixel limit.
    ///   - decoder: The decoder used to convert bytes to RGBA.
    /// - Returns: The decoded image.
    /// - Throws: `ImageLoadError` on rejection, `CancellationError` /
    ///   `URLError.cancelled` on cancellation.
    func load(
        _ urlString: String,
        cache: URLImageCache,
        timeout: TimeInterval,
        maxPixelCount: Int?,
        decoder: PureSwiftImageDecoder
    ) async throws -> RGBAImage {
        if let cached = cache.get(urlString) {
            try decoder.validateCachedImage(cached, maxPixelCount: maxPixelCount)
            return cached
        }

        if let existing = inFlight[urlString] {
            return try await Self.awaitTaskRespectingCancellation(existing.task)
        }

        let transport = self.transport
        let task = Task<RGBAImage, Error> {
            try await Self.perform(
                urlString: urlString,
                transport: transport,
                cache: cache,
                timeout: timeout,
                maxPixelCount: maxPixelCount,
                decoder: decoder
            )
        }
        inFlight[urlString] = InFlight(task: task)

        do {
            let image = try await Self.awaitTaskRespectingCancellation(task)
            inFlight.removeValue(forKey: urlString)
            return image
        } catch {
            inFlight.removeValue(forKey: urlString)
            throw error
        }
    }

    /// Awaits a task's value and forwards caller cancellation to it.
    ///
    /// The shared in-flight task cannot observe individual callers; this
    /// helper routes each caller's cancellation into the task so a
    /// cancelled caller sees `CancellationError` or `URLError.cancelled`
    /// exactly like a non-deduplicated load.
    private static func awaitTaskRespectingCancellation<T: Sendable>(
        _ task: Task<T, Error>
    ) async throws -> T {
        try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    // MARK: - Fetch + Validate

    /// Performs the transport call and validation outside the actor's
    /// isolation so a slow download does not stall other coordinator work.
    private static func perform(
        urlString: String,
        transport: any URLImageDataTransport,
        cache: URLImageCache,
        timeout: TimeInterval,
        maxPixelCount: Int?,
        decoder: PureSwiftImageDecoder
    ) async throws -> RGBAImage {
        guard let url = URL(string: urlString) else {
            throw ImageLoadError.downloadFailed("Invalid URL: \(urlString)")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.fetch(request: request)
        } catch let error as ImageLoadError {
            throw error
        } catch {
            throw ImageLoadError.downloadFailed(error.localizedDescription)
        }

        try validate(response: response, data: data, decoder: decoder)

        let image = try decoder.decode(data, maxPixelCount: maxPixelCount)
        cache.set(urlString, image: image)
        return image
    }

    /// Rejects responses with error status codes or oversized bodies.
    private static func validate(
        response: URLResponse,
        data: Data,
        decoder: PureSwiftImageDecoder
    ) throws {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ImageLoadError.downloadFailed(
                "HTTP \(http.statusCode) for \(http.url?.absoluteString ?? "URL")"
            )
        }

        let limit = decoder.maxInputBytes
        guard limit >= 0 else {
            throw ImageLoadError.inputTooLarge(byteCount: 0, limit: limit)
        }
        guard data.count <= limit else {
            throw ImageLoadError.inputTooLarge(byteCount: data.count, limit: limit)
        }
    }
}
