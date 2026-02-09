//  TUIKit - Terminal UI Kit for Swift
//  FrameModifierTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Test Helpers

/// Creates a default render context for testing.
private func testContext(width: Int = 40, height: Int = 24) -> RenderContext {
    RenderContext(availableWidth: width, availableHeight: height)
}

// MARK: - FrameModifier Tests

@MainActor
@Suite("FrameModifier Tests")
struct FrameModifierTests {

    @Test("FlexibleFrameView with maxWidth infinity fills available width")
    func frameMaxWidthInfinity() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: .infinity,
            minHeight: nil,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .center
        )
        let context = testContext(width: 30)
        let buffer = frame.renderToBuffer(context: context)

        #expect(buffer.width == 30)
    }

    @Test("FlexibleFrameView with fixed maxWidth constrains")
    func frameFixedMaxWidth() {
        let frame = FlexibleFrameView(
            content: Text("Short"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: .fixed(10),
            minHeight: nil,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .leading
        )
        let context = testContext(width: 40)
        let buffer = frame.renderToBuffer(context: context)

        // Content "Short" is 5 chars, no maxWidth expansion without infinity
        #expect(buffer.width <= 10)
    }

    @Test("FlexibleFrameView with minWidth enforces minimum")
    func frameMinWidth() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: 10,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: nil,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .leading
        )
        let context = testContext(width: 40)
        let buffer = frame.renderToBuffer(context: context)

        #expect(buffer.width >= 10)
    }

    @Test("FlexibleFrameView with minHeight enforces minimum")
    func frameMinHeight() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: 5,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .top
        )
        let context = testContext()
        let buffer = frame.renderToBuffer(context: context)

        #expect(buffer.height >= 5)
    }

    @Test("FlexibleFrameView alignment center")
    func frameCenterAlignment() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: 10,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: 3,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .center
        )
        let context = testContext()
        let buffer = frame.renderToBuffer(context: context)

        #expect(buffer.width >= 10)
        #expect(buffer.height >= 3)
        // Center vertically: content should be on line 1 (middle of 3)
        let contentLine = buffer.lines[1]
        #expect(contentLine.contains("Hi"))
        // Center horizontally: "Hi" is 2 chars, frame is 10, so 4 spaces on left
        let stripped = contentLine.stripped
        let leadingSpaces = stripped.prefix(while: { $0 == " " }).count
        #expect(leadingSpaces == 4, "Content should be horizontally centered with 4 leading spaces")
    }

    @Test("FlexibleFrameView alignment trailing")
    func frameTrailingAlignment() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: 10,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: nil,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .trailing
        )
        let context = testContext()
        let buffer = frame.renderToBuffer(context: context)

        // "Hi" should be right-aligned within 10 chars
        let line = buffer.lines[0]
        #expect(line.stripped.hasSuffix("Hi"))
    }

    @Test("FlexibleFrameView alignment bottom")
    func frameBottomAlignment() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: 3,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .bottom
        )
        let context = testContext()
        let buffer = frame.renderToBuffer(context: context)

        #expect(buffer.height >= 3)
        // Content on last line
        let lastLine = buffer.lines[buffer.height - 1]
        #expect(lastLine.contains("Hi"))
    }

    @Test("FlexibleFrameView maxHeight constrains available height for content")
    func frameMaxHeight() {
        // maxHeight constrains the availableHeight passed to child rendering,
        // but does not clip content that exceeds constraints. This matches
        // SwiftUI behavior where frame constraints inform layout, not clip.
        let frame = FlexibleFrameView(
            content: Text("Short"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: 5,
            idealHeight: nil,
            maxHeight: .fixed(10),
            alignment: .top
        )
        let context = testContext()
        let buffer = frame.renderToBuffer(context: context)

        // minHeight 5 expands the 1-line content to 5 lines
        #expect(buffer.height == 5)
    }

    @Test("FlexibleFrameView maxHeight infinity fills available space")
    func frameMaxHeightInfinity() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: nil,
            idealHeight: nil,
            maxHeight: .infinity,
            alignment: .top
        )
        var context = testContext()
        context.availableHeight = 10
        let buffer = frame.renderToBuffer(context: context)

        // Should expand to fill available height
        #expect(buffer.height == 10)
    }
}
