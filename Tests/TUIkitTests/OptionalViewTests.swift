//
//  OptionalViewTests.swift
//  TUIkit
//
//  Tests for Optional<View> conformance: rendering some/none, Renderable.
//

import Testing

@testable import TUIkit

@Suite("Optional View Tests")
struct OptionalViewTests {

    /// Helper to create a RenderContext with default test settings.
    private func testContext() -> RenderContext {
        RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            tuiContext: TUIContext()
        )
    }

    @Test("Optional.some renders the wrapped view")
    func someRendersView() {
        let optional: Text? = Text("Hello")
        let buffer = renderToBuffer(optional, context: testContext())
        #expect(buffer.lines[0].stripped == "Hello")
    }

    @Test("Optional.none renders empty buffer")
    func noneRendersEmpty() {
        let optional: Text? = nil
        let buffer = renderToBuffer(optional, context: testContext())
        #expect(buffer.isEmpty)
    }

    @Test("Optional Renderable conformance for some")
    func renderableSome() {
        let optional: Text? = Text("World")
        let renderable = optional as any Renderable
        let buffer = renderable.renderToBuffer(context: testContext())
        #expect(buffer.lines[0].stripped == "World")
    }

    @Test("Optional Renderable conformance for none")
    func renderableNone() {
        let optional: Text? = nil
        let renderable = optional as any Renderable
        let buffer = renderable.renderToBuffer(context: testContext())
        #expect(buffer.isEmpty)
    }

    @Test("Optional.some with styled view preserves styling")
    func somePreservesStyling() {
        let optional: Text? = Text("Styled").bold()
        let buffer = renderToBuffer(optional, context: testContext())
        // Should contain ANSI bold code
        #expect(buffer.lines[0].contains("\u{1B}["))
    }
}
