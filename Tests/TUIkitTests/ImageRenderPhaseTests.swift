//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageRenderPhaseTests.swift
//
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

/// Specifies the render-phase contract for `_ImageCore` (issue #27 slice):
/// rendering an image must never mutate state inside the traversal window.
/// The placeholder for a changed source is DERIVED while rendering; the
/// mounted loading task commits phase and last source from outside the
/// window, so no frame ever emits a body-side-effect diagnostic.
@MainActor
@Suite("Image Render Phase", .serialized)
struct ImageRenderPhaseTests {

    @Test("Rendering an image emits no traversal diagnostics", .timeLimit(.minutes(1)))
    func renderingEmitsNoTraversalDiagnostics() async throws {
        let tuiContext = TUIContext(imageLoader: StubImageLoader())
        let harness = FrameHarness(app: SwappableImageApp(), tuiContext: tuiContext)

        harness.renderFrame()

        #expect(tuiContext.runtimeDiagnostics.messages.isEmpty)

        let phaseBox = try #require(imagePhaseBox(in: tuiContext))
        while case .loading = phaseBox.value { await Task.yield() }
        harness.renderFrame()

        #expect(tuiContext.runtimeDiagnostics.messages.isEmpty)
    }

    @Test("Source change derives the placeholder without state writes", .timeLimit(.minutes(1)))
    func sourceChangeDerivesPlaceholder() async throws {
        let tuiContext = TUIContext(imageLoader: StubImageLoader())
        let app = SwappableImageApp()
        let harness = FrameHarness(app: app, tuiContext: tuiContext)

        harness.renderFrame()
        let phaseBox = try #require(imagePhaseBox(in: tuiContext))
        while case .loading = phaseBox.value { await Task.yield() }
        harness.renderFrame()

        app.cell.source = .file("/stub/b.png")
        let outputCountBeforeChange = harness.terminal.writtenOutput.count
        harness.renderFrame()

        // The placeholder appears in the SAME frame as the new source …
        let changeFrameOutput = harness.terminal.writtenOutput[outputCountBeforeChange...].joined()
        #expect(changeFrameOutput.contains(placeholderSpinnerGlyph))
        // … and nothing mutated state during the traversal.
        #expect(tuiContext.runtimeDiagnostics.messages.isEmpty)

        // The replacement task commits phase and source after the frame.
        let sourceBox = try #require(imageLastSourceBox(in: tuiContext))
        while sourceBox.value != .file("/stub/b.png") { await Task.yield() }
        harness.renderFrame()

        #expect(tuiContext.runtimeDiagnostics.messages.isEmpty)
    }
}

// MARK: - State Access

/// The spinner glyph `_ImageCore.renderPlaceholder` draws while loading.
private let placeholderSpinnerGlyph = "⠋"

/// Returns the image view's phase box (`_ImageCore` property index 0).
///
/// The fixtures render exactly one image, so the single stored identity is
/// the image's. Returns `nil` when no frame has hydrated state yet.
@MainActor
private func imagePhaseBox(in tuiContext: TUIContext) -> StateBox<ImageLoadingPhase>? {
    guard let identity = tuiContext.stateStorage.storedIdentities.first else { return nil }
    return tuiContext.stateStorage.storage(
        for: StateStorage.StateKey(identity: identity, propertyIndex: 0),
        default: .loading
    )
}

/// Returns the image view's last-source box (`_ImageCore` property index 1).
@MainActor
private func imageLastSourceBox(in tuiContext: TUIContext) -> StateBox<ImageSource?>? {
    guard let identity = tuiContext.stateStorage.storedIdentities.first else { return nil }
    return tuiContext.stateStorage.storage(
        for: StateStorage.StateKey(identity: identity, propertyIndex: 1),
        default: nil
    )
}

// MARK: - Fixtures

/// Serves a deterministic single-pixel image for any request, keeping the
/// file system and network out of the tests.
private struct StubImageLoader: ImageLoader {
    private let image = RGBAImage(
        width: 1,
        height: 1,
        pixels: [RGBA(r: 255, g: 255, b: 255)]
    )

    func loadImage(from path: String) throws -> RGBAImage {
        image
    }

    func loadImage(from data: Data) throws -> RGBAImage {
        image
    }
}

/// Mutable source slot shared between a test and its app fixture.
@MainActor
private final class ImageSourceCell {
    var source: ImageSource = .file("/stub/a.png")
}

/// Renders one image whose source the test swaps between frames.
private struct SwappableImageApp: App {
    let cell = ImageSourceCell()

    init() {}

    var body: some Scene {
        WindowGroup {
            Image(cell.source)
        }
    }
}
