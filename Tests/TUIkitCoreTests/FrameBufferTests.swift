//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FrameBufferTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkitCore

@MainActor
@Suite("FrameBuffer Tests")
struct FrameBufferTests {

    @Test("Empty buffer has zero dimensions")
    func emptyBuffer() {
        let buffer = FrameBuffer()
        #expect(buffer.width == 0)
        #expect(buffer.height == 0)
        #expect(buffer.isEmpty)
    }

    @Test("Single line buffer has correct dimensions")
    func singleLine() {
        let buffer = FrameBuffer(text: "Hello")
        #expect(buffer.width == 5)
        #expect(buffer.height == 1)
        #expect(buffer.lines == ["Hello"])
    }

    @Test("Vertical append stacks lines")
    func verticalAppend() {
        var buffer = FrameBuffer(text: "Line 1")
        buffer.appendVertically(FrameBuffer(text: "Line 2"))
        #expect(buffer.height == 2)
        #expect(buffer.lines == ["Line 1", "Line 2"])
    }

    @Test("Vertical append with spacing")
    func verticalAppendWithSpacing() {
        var buffer = FrameBuffer(text: "Top")
        buffer.appendVertically(FrameBuffer(text: "Bottom"), spacing: 2)
        #expect(buffer.height == 4)
        #expect(buffer.lines == ["Top", "", "", "Bottom"])
    }

    @Test("Horizontal append places side by side")
    func horizontalAppend() {
        var buffer = FrameBuffer(text: "Left")
        buffer.appendHorizontally(FrameBuffer(text: "Right"), spacing: 1)
        #expect(buffer.height == 1)
        #expect(buffer.lines == ["Left Right"])
    }

    @Test("Horizontal append with different heights pads correctly")
    func horizontalAppendDifferentHeights() {
        var left = FrameBuffer(lines: ["AB", "CD"])
        let right = FrameBuffer(text: "X")
        left.appendHorizontally(right, spacing: 1)
        #expect(left.height == 2)
        #expect(left.lines[0] == "AB X")
        // Row 1: "CD" padded to width 2, spacing " ", no right content
        #expect(left.lines[1] == "CD ")
    }

    @Test("ANSI codes are excluded from width calculation")
    func ansiStrippedWidth() {
        let styled = "\u{1B}[1mBold\u{1B}[0m"
        let buffer = FrameBuffer(text: styled)
        #expect(buffer.width == 4)  // "Bold" is 4 chars
    }

    @Test("Horizontal append with ANSI codes pads correctly")
    func horizontalAppendWithAnsi() {
        let styled = "\u{1B}[1mHi\u{1B}[0m"
        var left = FrameBuffer(text: styled)
        left.appendHorizontally(FrameBuffer(text: "There"), spacing: 1)
        #expect(left.height == 1)
        // "Hi" (styled) + " " (spacing) + "There"
        #expect(left.lines[0].stripped == "Hi There")
    }

    @Test("Line mutation rebuilds cell width")
    func lineMutationRebuildsSurface() {
        var buffer = FrameBuffer(text: "A")

        buffer.lines[0] = "e\u{301}界"

        #expect(buffer.width == 3)
        #expect(buffer.lines == ["e\u{301}界"])
    }

    @Test("FrameBuffer rejects embedded terminal commands")
    func rejectsTerminalCommands() {
        let buffer = FrameBuffer(text: "A\u{1B}]0;owned\u{07}B\u{1B}[2JC")

        #expect(buffer.lines == ["ABC"])
        #expect(buffer.width == 3)
    }

    @Test("Transparent overlay spaces preserve base cells")
    func transparentOverlaySpaces() {
        let base = FrameBuffer(text: "ABC")
        let overlay = FrameBuffer(text: " X ")

        let result = base.composited(with: overlay, at: (x: 0, y: 0))

        #expect(result.lines == ["AXC"])
    }

    @Test("Overlay clears complete wide graphemes")
    func overlayClearsWideGrapheme() {
        let base = FrameBuffer(text: "A界B")
        let overlay = FrameBuffer(text: "X")

        let result = base.composited(with: overlay, at: (x: 2, y: 0))

        #expect(result.lines == ["A XB"])
        #expect(result.width == 4)
    }

    @Test("RGB-styled compatibility lines remain valid strings")
    func rgbStyledLineLifetime() {
        let styled = "\u{1B}[38;2;229;229;229mOver\u{1B}[0m"
        let buffer = FrameBuffer(text: styled)

        #expect(buffer.lines[0].stripped == "Over")
    }
}
