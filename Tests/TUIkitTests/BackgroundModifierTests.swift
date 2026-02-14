//  TUIKit - Terminal UI Kit for Swift
//  BackgroundModifierTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Test Helpers

/// Creates a default render context for testing.
private func testContext(width: Int = 40, height: Int = 24) -> RenderContext {
    RenderContext(availableWidth: width, availableHeight: height, tuiContext: TUIContext())
}

// MARK: - BackgroundModifier Tests

@MainActor
@Suite("BackgroundModifier Tests")
struct BackgroundModifierTests {

    @Test("Background modifier applies ANSI background code")
    func backgroundAppliesCode() {
        let modifier = BackgroundModifier(color: .red)
        let buffer = FrameBuffer(lines: ["Hello"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        #expect(result.height == 1)
        // Should contain ANSI red background code (41)
        let line = result.lines[0]
        #expect(line.contains("\u{1B}[41m"))
        #expect(line.contains("Hello"))
        // Should end with reset
        #expect(line.hasSuffix(ANSIRenderer.reset))
    }

    @Test("Background modifier preserves line count")
    func backgroundPreservesLineCount() {
        let modifier = BackgroundModifier(color: .blue)
        let buffer = FrameBuffer(lines: ["Line 1", "Line 2", "Line 3"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        #expect(result.height == 3)
    }

    @Test("Background modifier on empty buffer returns empty")
    func backgroundEmptyBuffer() {
        let modifier = BackgroundModifier(color: .green)
        let buffer = FrameBuffer()
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        #expect(result.isEmpty)
    }

    @Test("Background modifier pads lines to full width")
    func backgroundPadsLines() {
        let modifier = BackgroundModifier(color: .red)
        let buffer = FrameBuffer(lines: ["Short", "VeryLongLine"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        // Both lines should have the same visible width after padding
        #expect(result.lines[0].strippedLength == result.lines[1].strippedLength)
    }
}
