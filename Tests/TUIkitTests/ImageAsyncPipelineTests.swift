//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageAsyncPipelineTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

/// End-to-end coverage for the async URL image pipeline inside
/// `_ImageCore`: the mounted lifecycle task awaits the async loader,
/// commits phase and source together, and never mutates state from
/// within the traversal window.
@MainActor
@Suite("Image Async Pipeline", .serialized)
struct ImageAsyncPipelineTests {

    @Test(
        "URL sources commit their phase through the async loader",
        .timeLimit(.minutes(1))
    )
    func urlSourceCommitsThroughAsyncLoader() async throws {
        let loader = SlowURLImageLoader(pixel: RGBA(r: 128, g: 64, b: 32))
        let tuiContext = TUIContext(imageLoader: loader)
        let harness = FrameHarness(app: URLImageApp(), tuiContext: tuiContext)

        // First frame renders the loading placeholder; the async task is
        // recorded for the frame commit and completes shortly after.
        harness.renderFrame()

        #expect(tuiContext.runtimeDiagnostics.messages.isEmpty)

        // Give the injected loader up to a second to complete its call.
        let deadline = Date().addingTimeInterval(1.0)
        while Date() < deadline, await loader.calls == 0 {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        #expect(await loader.calls == 1)

        // A follow-up frame renders the committed image without traversal
        // diagnostics: no state was mutated by reading the same source.
        harness.renderFrame()
        #expect(tuiContext.runtimeDiagnostics.messages.isEmpty)
    }
}

// MARK: - Fixtures

/// An `ImageLoader` whose URL path counts invocations and simulates a
/// short round-trip.
private actor SlowURLImageLoader: ImageLoader {
    private(set) var calls = 0
    private let image: RGBAImage

    init(pixel: RGBA) {
        self.image = RGBAImage(width: 1, height: 1, pixels: [pixel])
    }

    nonisolated func loadImage(from path: String) throws -> RGBAImage {
        fatalError("URL fixture never touches file sources")
    }

    nonisolated func loadImage(from data: Data) throws -> RGBAImage {
        fatalError("URL fixture never touches raw data")
    }

    func loadImage(
        from urlString: String,
        cache: URLImageCache,
        timeout: TimeInterval,
        maxPixelCount: Int?
    ) async throws -> RGBAImage {
        try await Task.sleep(nanoseconds: 5_000_000)
        calls += 1
        cache.set(urlString, image: image)
        return image
    }
}

private struct URLImageApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            Image(.url("https://async.test/image.png"))
        }
    }
}
