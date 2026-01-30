//
//  DimmedModifierTests.swift
//  TUIkit
//
//  Tests for DimmedModifier: dim effect application, edge cases, multi-line.
//

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

    @Test("DimmedModifier conforms to Renderable")
    func conformsToRenderable() {
        let modifier = DimmedModifier(content: Text("Test"))
        #expect(modifier is any Renderable)
    }

    @Test("Dimmed text contains ANSI dim code")
    func dimCodePresent() {
        let view = Text("Hello").dimmed()
        let buffer = render(view)
        #expect(buffer.lines.count == 1)
        // ESC[2m is the ANSI dim code
        #expect(buffer.lines[0].contains("\u{1B}[2m"))
    }

    @Test("Dimmed empty view returns empty buffer")
    func dimmedEmptyView() {
        let view = EmptyView().dimmed()
        let buffer = render(view)
        #expect(buffer.isEmpty)
    }

    @Test("Dimmed multi-line view dims each line")
    func dimmedMultiLine() {
        let view = VStack {
            Text("Line 1")
            Text("Line 2")
            Text("Line 3")
        }.dimmed()
        let buffer = render(view)
        #expect(buffer.height == 3)
        // Each line should have the dim code
        for line in buffer.lines {
            #expect(line.contains("\u{1B}[2m"))
        }
    }

    @Test("dimmed() View extension creates DimmedModifier")
    func viewExtension() {
        let view = Text("Hello").dimmed()
        #expect(view is DimmedModifier<Text>)
    }
}
