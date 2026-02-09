//  TUIKit - Terminal UI Kit for Swift
//  PaddingModifierTests.swift
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

// MARK: - PaddingModifier Tests

@MainActor
@Suite("PaddingModifier Tests")
struct PaddingModifierTests {

    @Test("Padding adds empty lines for top and bottom")
    func paddingTopBottom() {
        let modifier = PaddingModifier(insets: EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
        let buffer = FrameBuffer(lines: ["Hello"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        // 1 top + 1 content + 1 bottom = 3
        #expect(result.height == 3)
        #expect(result.lines[0].trimmingCharacters(in: .whitespaces).isEmpty)
        #expect(result.lines[1] == "Hello")
        #expect(result.lines[2].trimmingCharacters(in: .whitespaces).isEmpty)
    }

    @Test("Padding adds spaces for leading and trailing")
    func paddingLeadingTrailing() {
        let modifier = PaddingModifier(insets: EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 3))
        let buffer = FrameBuffer(lines: ["Hi"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        #expect(result.height == 1)
        // "  Hi   " — 2 leading + "Hi" + 3 trailing
        #expect(result.lines[0] == "  Hi   ")
    }

    @Test("Padding all sides")
    func paddingAllSides() {
        let modifier = PaddingModifier(insets: EdgeInsets(all: 1))
        let buffer = FrameBuffer(lines: ["X"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        // 1 top + 1 content + 1 bottom = 3
        #expect(result.height == 3)
        // Content line: 1 leading + "X" + 1 trailing = " X "
        #expect(result.lines[1] == " X ")
    }

    @Test("Padding on empty buffer returns empty")
    func paddingEmptyBuffer() {
        let modifier = PaddingModifier(insets: EdgeInsets(all: 2))
        let buffer = FrameBuffer()
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        // Only padding lines (no content)
        #expect(result.height == 4)  // 2 top + 0 content + 2 bottom
    }

    @Test("Padding preserves multiple content lines")
    func paddingMultipleLines() {
        let modifier = PaddingModifier(insets: EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1))
        let buffer = FrameBuffer(lines: ["AAA", "BBB"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        // 1 top + 2 content + 1 bottom = 4
        #expect(result.height == 4)
        #expect(result.lines[1] == " AAA ")
        #expect(result.lines[2] == " BBB ")
    }

    @Test("Zero padding returns original dimensions")
    func paddingZero() {
        let modifier = PaddingModifier(insets: EdgeInsets())
        let buffer = FrameBuffer(lines: ["Test"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        #expect(result.height == 1)
        #expect(result.lines[0] == "Test")
    }
}
