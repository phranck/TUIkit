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

    @Test("Overlay with leading alignment places overlay at start")
    func leadingAlignment() {
        let base = Text("Hello World")
        let overlay = Text("X")
        let view = OverlayModifier(base: base, overlay: overlay, alignment: .leading)
        let buffer = render(view)
        let line = buffer.lines[0].stripped
        #expect(line.hasPrefix("X"))
    }

    @Test("Overlay with trailing alignment places overlay at end")
    func trailingAlignment() {
        let base = Text("Hello World")
        let overlay = Text("X")
        let view = OverlayModifier(base: base, overlay: overlay, alignment: .trailing)
        let buffer = render(view)
        let line = buffer.lines[0].stripped
        #expect(line.hasSuffix("X"))
    }

    @Test("Overlay with topLeading alignment places overlay at top-left")
    func topLeadingAlignment() {
        let base = VStack {
            Text("Line 1")
            Text("Line 2")
            Text("Line 3")
        }
        let overlay = Text("X")
        let view = OverlayModifier(base: base, overlay: overlay, alignment: .topLeading)
        let buffer = render(view)
        #expect(buffer.height >= 3)
        let firstLine = buffer.lines[0].stripped
        #expect(firstLine.hasPrefix("X"))
    }

    @Test("Overlay with bottomTrailing alignment places overlay at bottom-right")
    func bottomTrailingAlignment() {
        let base = VStack {
            Text("Line 1")
            Text("Line 2")
            Text("Line 3")
        }
        let overlay = Text("X")
        let view = OverlayModifier(base: base, overlay: overlay, alignment: .bottomTrailing)
        let buffer = render(view)
        #expect(buffer.height >= 3)
        let lastLine = buffer.lines[buffer.height - 1].stripped
        #expect(lastLine.hasSuffix("X"))
    }
}
