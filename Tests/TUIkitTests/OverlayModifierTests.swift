//
//  OverlayModifierTests.swift
//  TUIkit
//
//  Tests for OverlayModifier: alignment positioning, edge cases,
//  and View extension.
//

import Testing

@testable import TUIkit

@Suite("OverlayModifier Tests")
struct OverlayModifierTests {

    /// Helper to create a RenderContext with default test settings.
    private func testContext() -> RenderContext {
        RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            tuiContext: TUIContext()
        )
    }

    /// Helper to render a view to a FrameBuffer.
    private func render<V: View>(_ view: V) -> FrameBuffer {
        renderToBuffer(view, context: testContext())
    }

    @Test("OverlayModifier conforms to Renderable")
    func conformsToRenderable() {
        let modifier = OverlayModifier(
            base: Text("Base"),
            overlay: Text("Over"),
            alignment: .center
        )
        #expect(modifier is any Renderable)
    }

    @Test("Overlay with empty base returns overlay")
    func emptyBaseReturnsOverlay() {
        let view = OverlayModifier(
            base: EmptyView(),
            overlay: Text("Over"),
            alignment: .center
        )
        let buffer = render(view)
        #expect(buffer.lines[0].stripped == "Over")
    }

    @Test("Overlay with empty overlay returns base")
    func emptyOverlayReturnsBase() {
        let view = OverlayModifier(
            base: Text("Base"),
            overlay: EmptyView(),
            alignment: .center
        )
        let buffer = render(view)
        #expect(buffer.lines[0].stripped == "Base")
    }

    @Test("Overlay preserves base dimensions")
    func preservesBaseDimensions() {
        let base = Text("Hello World")
        let overlay = Text("Hi")
        let view = OverlayModifier(
            base: base,
            overlay: overlay,
            alignment: .center
        )
        let baseBuffer = render(base)
        let overlayBuffer = render(view)
        #expect(overlayBuffer.width == baseBuffer.width)
        #expect(overlayBuffer.height == baseBuffer.height)
    }

    @Test("overlay() View extension creates OverlayModifier")
    func viewExtension() {
        let view = Text("Base").overlay {
            Text("Over")
        }
        #expect(view is OverlayModifier<Text, Text>)
    }

    @Test("overlay with leading alignment")
    func leadingAlignment() {
        let view = Text("Base").overlay(alignment: .leading) {
            Text("Over")
        }
        let buffer = render(view)
        // Overlay should be at the start
        #expect(!buffer.isEmpty)
    }

    @Test("overlay with trailing alignment")
    func trailingAlignment() {
        let view = Text("Base").overlay(alignment: .trailing) {
            Text("Over")
        }
        let buffer = render(view)
        #expect(!buffer.isEmpty)
    }

    @Test("overlay with topLeading alignment")
    func topLeadingAlignment() {
        let view = OverlayModifier(
            base: Text("Base"),
            overlay: Text("X"),
            alignment: .topLeading
        )
        let buffer = render(view)
        #expect(!buffer.isEmpty)
    }

    @Test("overlay with bottomTrailing alignment")
    func bottomTrailingAlignment() {
        let view = OverlayModifier(
            base: Text("Base"),
            overlay: Text("X"),
            alignment: .bottomTrailing
        )
        let buffer = render(view)
        #expect(!buffer.isEmpty)
    }
}
