//  🖥️ TUIKit — Terminal UI Kit for Swift
//  DimmedModifierTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@Suite("DimmedModifier Tests")
struct DimmedModifierTests {

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

    @Test("Dimmed text strips original styling and applies uniform colors")
    func dimmedStripsAndRecolors() {
        let view = Text("Hello").dimmed()
        let buffer = render(view)
        #expect(buffer.lines.count == 1)
        // Should NOT contain the old ANSI dim code — we use palette colors now
        #expect(!buffer.lines[0].contains("\u{1B}[2m"))
        // Visible text must survive the stripping
        #expect(buffer.lines[0].stripped.contains("Hello"))
        // Must contain RGB color codes (from palette foregroundTertiary/overlayBackground)
        #expect(buffer.lines[0].contains("\u{1B}["))
    }

    @Test("Dimmed empty view returns empty buffer")
    func dimmedEmptyView() {
        let view = EmptyView().dimmed()
        let buffer = render(view)
        #expect(buffer.isEmpty)
    }

    @Test("Dimmed multi-line view flattens each line uniformly")
    func dimmedMultiLine() {
        let view = VStack {
            Text("Line 1")
            Text("Line 2")
            Text("Line 3")
        }.dimmed()
        let buffer = render(view)
        #expect(buffer.height == 3)
        // Each line should have the visible text and uniform palette-based styling
        for line in buffer.lines {
            #expect(!line.contains("\u{1B}[2m"))
            #expect(!line.stripped.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    @Test("Dimmed lines are padded to full buffer width")
    func dimmedPadsToFullWidth() {
        let view = Text("Short").dimmed()
        let buffer = render(view)
        let visibleWidth = buffer.lines[0].strippedLength
        // The dimmed line should be padded to the buffer width
        #expect(visibleWidth == buffer.width)
    }
}
