//  🖥️ TUIKit — Terminal UI Kit for Swift
//  URLImageCoordinatorTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import TUIkitImage

@Suite("URL Image Coordinator", .timeLimit(.minutes(1)))
struct URLImageCoordinatorTests {

    /// One-pixel PNG shared by all fixtures.
    private static let onePixelPNGBytes = Data(
        base64Encoded: """
        iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==
        """.replacingOccurrences(of: "\n", with: "")
    )!

    /// Creates a fresh coordinator with a scripted transport.
    private func makeCoordinator(
        transport: RecordingURLTransport = RecordingURLTransport()
    ) -> (URLImageCoordinator, RecordingURLTransport) {
        (URLImageCoordinator(transport: transport), transport)
    }

    // MARK: - Cache Hit/Miss

    @Test("A cache hit skips the transport")
    func cacheHitSkipsTransport() async throws {
        let cache = URLImageCache()
        let cachedImage = RGBAImage(
            width: 1,
            height: 1,
            pixels: [RGBA(r: 0, g: 0, b: 0)]
        )
        cache.set("https://cached.test/image.png", image: cachedImage)

        let (coordinator, transport) = makeCoordinator()
        let image = try await coordinator.load(
            "https://cached.test/image.png",
            cache: cache,
            timeout: 5,
            maxPixelCount: nil,
            decoder: PureSwiftImageDecoder(limits: .default)
        )

        #expect(image.width == 1)
        let count = await transport.calls.count
        #expect(count == 0)
    }

    @Test("A cache miss fetches, decodes, and stores")
    func cacheMissFetchesAndStores() async throws {
        let cache = URLImageCache()
        let transport = RecordingURLTransport()
        await transport.enqueue(
            data: Self.onePixelPNGBytes,
            response: HTTPURLResponse(
                url: URL(string: "https://miss.test/image.png")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "image/png"]
            )!
        )
        let (coordinator, _) = makeCoordinator(transport: transport)

        _ = try await coordinator.load(
            "https://miss.test/image.png",
            cache: cache,
            timeout: 5,
            maxPixelCount: nil,
            decoder: PureSwiftImageDecoder(limits: .default)
        )

        #expect(cache.get("https://miss.test/image.png") != nil)
        #expect(await transport.calls.count == 1)
    }

    // MARK: - Deduplication

    @Test("Identical in-flight URLs share a single transport call")
    func deduplicatesInFlightRequests() async throws {
        let cache = URLImageCache()
        let transport = RecordingURLTransport()
        await transport.pause(atCallIndex: 0)
        await transport.enqueue(
            data: Self.onePixelPNGBytes,
            response: HTTPURLResponse(
                url: URL(string: "https://dedup.test/image.png")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "image/png"]
            )!
        )
        let (coordinator, _) = makeCoordinator(transport: transport)

        async let first = coordinator.load(
            "https://dedup.test/image.png",
            cache: cache,
            timeout: 5,
            maxPixelCount: nil,
            decoder: PureSwiftImageDecoder(limits: .default)
        )
        async let second = coordinator.load(
            "https://dedup.test/image.png",
            cache: cache,
            timeout: 5,
            maxPixelCount: nil,
            decoder: PureSwiftImageDecoder(limits: .default)
        )

        // Wait for both tasks to reach the transport before releasing it.
        try await Task.sleep(nanoseconds: 50_000_000)
        await transport.resumePaused()

        _ = try await first
        _ = try await second

        #expect(await transport.calls.count == 1)
    }

    // MARK: - Validation

    @Test("A non-2xx response fails with downloadFailed")
    func nonSuccessStatusFails() async {
        let transport = RecordingURLTransport()
        await transport.enqueue(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://fail.test/image.png")!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
        )
        let (coordinator, _) = makeCoordinator(transport: transport)

        do {
            _ = try await coordinator.load(
                "https://fail.test/image.png",
                cache: URLImageCache(),
                timeout: 5,
                maxPixelCount: nil,
                decoder: PureSwiftImageDecoder(limits: .default)
            )
            Issue.record("Expected 404 to reject")
        } catch let error as ImageLoadError {
            guard case .downloadFailed(let reason) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(reason.contains("404"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("A response above the loader byte limit is rejected")
    func rejectsOversizedResponse() async {
        let transport = RecordingURLTransport()
        await transport.enqueue(
            data: Data(repeating: 0, count: 32),
            response: HTTPURLResponse(
                url: URL(string: "https://big.test/image.png")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        )
        let (coordinator, _) = makeCoordinator(transport: transport)
        let decoder = PureSwiftImageDecoder(limits: ImageDecodingLimits(maxInputBytes: 4))

        do {
            _ = try await coordinator.load(
                "https://big.test/image.png",
                cache: URLImageCache(),
                timeout: 5,
                maxPixelCount: nil,
                decoder: decoder
            )
            Issue.record("Expected byte limit to reject the download")
        } catch let error as ImageLoadError {
            guard case .inputTooLarge(let byteCount, limit: 4) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(byteCount == 32)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Cancellation

    @Test("A cancelled caller forwards cancellation to the in-flight task")
    func cancellationForwardsToInFlightTask() async throws {
        let transport = RecordingURLTransport()
        await transport.pause(atCallIndex: 0)
        let (coordinator, _) = makeCoordinator(transport: transport)

        let task = Task {
            try await coordinator.load(
                "https://cancel.test/image.png",
                cache: URLImageCache(),
                timeout: 5,
                maxPixelCount: nil,
                decoder: PureSwiftImageDecoder(limits: .default)
            )
        }
        try await Task.sleep(nanoseconds: 20_000_000)

        // Cancelling the outer caller must eventually cancel the shared
        // in-flight task; the paused transport observes that as a
        // cancelled resume.
        task.cancel()

        let observed = await transport.awaitCancelledFetch(timeout: 1.0)
        #expect(observed == true)

        // Release the paused fetch so pending clean-up completes and the
        // test never leaves a live task behind.
        await transport.resumePaused()
        _ = try? await task.value
    }
}
