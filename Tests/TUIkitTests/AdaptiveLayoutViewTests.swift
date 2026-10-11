//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AdaptiveLayoutViewTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("GeometryReader and ViewThatFits")
struct AdaptiveLayoutViewTests {

    /// Creates an isolated render context.
    private func testContext(width: Int, height: Int) -> RenderContext {
        RenderContext(
            availableWidth: width,
            availableHeight: height,
            tuiContext: TUIContext()
        )
    }

    // MARK: - GeometryReader

    @Test("GeometryReader reports the proposed size in cells")
    func geometryReaderReportsSize() {
        let reader = GeometryReader { proxy in
            Text("w:\(Int(proxy.size.width)) h:\(Int(proxy.size.height))")
        }

        let buffer = renderToBuffer(reader, context: testContext(width: 24, height: 6))

        #expect(buffer.lines.first?.stripped == "w:24 h:6")
    }

    @Test("GeometryReader expands to fill its proposed space")
    func geometryReaderExpands() {
        let reader = GeometryReader { _ in Text("x") }

        let buffer = renderToBuffer(reader, context: testContext(width: 10, height: 4))

        #expect(buffer.height == 4)
        #expect(buffer.width == 10)
    }

    // MARK: - ViewThatFits

    @Test("ViewThatFits picks the first candidate that fits")
    func viewThatFitsPicksFirstFitting() {
        let adaptive = ViewThatFits {
            Text("this is the very long variant")
            Text("medium length")
            Text("short")
        }

        let wide = renderToBuffer(adaptive, context: testContext(width: 40, height: 3))
        #expect(wide.lines.first?.stripped == "this is the very long variant")

        let medium = renderToBuffer(adaptive, context: testContext(width: 16, height: 3))
        #expect(medium.lines.first?.stripped == "medium length")

        let narrow = renderToBuffer(adaptive, context: testContext(width: 7, height: 3))
        #expect(narrow.lines.first?.stripped == "short")
    }

    @Test("ViewThatFits falls back to the last candidate when nothing fits")
    func viewThatFitsFallsBack() {
        let adaptive = ViewThatFits {
            Text("long candidate")
            Text("still long")
        }

        let buffer = renderToBuffer(adaptive, context: testContext(width: 4, height: 3))

        #expect(buffer.lines.first?.stripped.hasPrefix("stil") == true)
    }

    @Test("ViewThatFits constrained to one axis ignores the other")
    func viewThatFitsAxisConstrained() {
        let tall = Text("a\nb\nc\nd")
        let adaptive = ViewThatFits(in: .horizontal) {
            tall
            Text("x")
        }

        // Height 2 is too small for the 4-line candidate, but only the
        // horizontal axis is constrained, so the first candidate wins.
        let buffer = renderToBuffer(adaptive, context: testContext(width: 10, height: 2))

        #expect(buffer.lines.first?.stripped == "a")
    }
}
