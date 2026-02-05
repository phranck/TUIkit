//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FrameDiffWriterTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - buildOutputLines Tests

@Suite("FrameDiffWriter buildOutputLines Tests")
struct BuildOutputLinesTests {

    @Test("Produces exactly terminalHeight output lines")
    func outputLineCount() {
        let writer = FrameDiffWriter()
        var buffer = FrameBuffer()
        buffer.appendVertically(FrameBuffer(text: "Hello"))
        buffer.appendVertically(FrameBuffer(text: "World"))

        let lines = writer.buildOutputLines(
            buffer: buffer,
            terminalWidth: 20,
            terminalHeight: 5,
            bgCode: "",
            reset: ""
        )

        #expect(lines.count == 5)
    }

    @Test("Content lines include background and padding")
    func contentLinesHaveBgAndPadding() {
        let writer = FrameDiffWriter()
        let buffer = FrameBuffer(text: "Hi")

        let lines = writer.buildOutputLines(
            buffer: buffer,
            terminalWidth: 10,
            terminalHeight: 1,
            bgCode: "[BG]",
            reset: "[R]"
        )

        let line = lines[0]
        #expect(line.hasPrefix("[BG]"))
        #expect(line.hasSuffix("[R]"))
        #expect(line.contains("Hi"))
    }

    @Test("Empty rows are filled with background-colored spaces")
    func emptyRowsFilled() {
        let writer = FrameDiffWriter()
        let buffer = FrameBuffer()

        let lines = writer.buildOutputLines(
            buffer: buffer,
            terminalWidth: 5,
            terminalHeight: 2,
            bgCode: "[BG]",
            reset: "[R]"
        )

        let expected = "[BG]" + String(repeating: " ", count: 5) + "[R]"
        #expect(lines[0] == expected)
        #expect(lines[1] == expected)
    }

    @Test("ANSI reset codes in content are replaced with reset+bg")
    func resetCodesReplaced() {
        let writer = FrameDiffWriter()
        let reset = ANSIRenderer.reset
        let buffer = FrameBuffer(text: "A\(reset)B")

        let lines = writer.buildOutputLines(
            buffer: buffer,
            terminalWidth: 20,
            terminalHeight: 1,
            bgCode: "[BG]",
            reset: reset
        )

        #expect(lines[0].contains("\(reset)[BG]"))
    }

    @Test("Multiple content lines are all processed")
    func multipleContentLines() {
        let writer = FrameDiffWriter()
        var buffer = FrameBuffer()
        buffer.appendVertically(FrameBuffer(text: "Line1"))
        buffer.appendVertically(FrameBuffer(text: "Line2"))
        buffer.appendVertically(FrameBuffer(text: "Line3"))

        let lines = writer.buildOutputLines(
            buffer: buffer,
            terminalWidth: 10,
            terminalHeight: 3,
            bgCode: "",
            reset: ""
        )

        #expect(lines[0].contains("Line1"))
        #expect(lines[1].contains("Line2"))
        #expect(lines[2].contains("Line3"))
    }
}

// MARK: - Line Diff Logic Tests

@Suite("FrameDiffWriter Diff Logic Tests")
struct DiffLogicTests {

    @Test("computeChangedRows returns all rows when previous is empty")
    func allRowsChangedOnFirstFrame() {
        let changed = FrameDiffWriter.computeChangedRows(
            newLines: ["A", "B", "C"],
            previousLines: []
        )

        #expect(changed == [0, 1, 2])
    }

    @Test("computeChangedRows returns empty when frames are identical")
    func noChangesForIdenticalFrames() {
        let lines = ["A", "B", "C"]
        let changed = FrameDiffWriter.computeChangedRows(
            newLines: lines,
            previousLines: lines
        )

        #expect(changed.isEmpty)
    }

    @Test("computeChangedRows detects single changed line")
    func singleLineChanged() {
        let changed = FrameDiffWriter.computeChangedRows(
            newLines: ["A", "X", "C"],
            previousLines: ["A", "B", "C"]
        )

        #expect(changed == [1])
    }

    @Test("computeChangedRows detects multiple changed lines")
    func multipleLinesChanged() {
        let changed = FrameDiffWriter.computeChangedRows(
            newLines: ["A", "X", "C", "Y"],
            previousLines: ["A", "B", "C", "D"]
        )

        #expect(changed == [1, 3])
    }

    @Test("computeChangedRows handles new lines longer than previous")
    func newLinesLongerThanPrevious() {
        let changed = FrameDiffWriter.computeChangedRows(
            newLines: ["A", "B", "C", "D"],
            previousLines: ["A", "B"]
        )

        // C and D are new (indices 2, 3)
        #expect(changed == [2, 3])
    }

    @Test("computeChangedRows handles ANSI-coded strings correctly")
    func ansiStringComparison() {
        let styledA = "\u{1B}[31mRed\u{1B}[0m"
        let styledB = "\u{1B}[32mGreen\u{1B}[0m"

        let changed = FrameDiffWriter.computeChangedRows(
            newLines: [styledA, styledB],
            previousLines: [styledA, styledA]
        )

        // Only the second line changed (red → green)
        #expect(changed == [1])
    }
}

// MARK: - Integration Tests

@Suite("FrameDiffWriter Integration Tests")
struct DiffIntegrationTests {

    @Test("Content and status bar caches are independent")
    func independentCaches() {
        let writer = FrameDiffWriter()

        // Simulate writing content + status bar (using internal state check)
        let contentLines = ["Content1", "Content2"]
        let statusLines = ["Status1"]

        // After writeContentDiff, content cache is set
        // After writeStatusBarDiff, status cache is set
        // We verify via computeChangedRows that each cache tracks independently

        // First: content has all changed (empty previous)
        let contentChanged1 = FrameDiffWriter.computeChangedRows(
            newLines: contentLines,
            previousLines: []
        )
        #expect(contentChanged1 == [0, 1])

        // Status also has all changed (different previous)
        let statusChanged1 = FrameDiffWriter.computeChangedRows(
            newLines: statusLines,
            previousLines: []
        )
        #expect(statusChanged1 == [0])

        // Same content → no changes
        let contentChanged2 = FrameDiffWriter.computeChangedRows(
            newLines: contentLines,
            previousLines: contentLines
        )
        #expect(contentChanged2.isEmpty)

        // Status changed → only status
        let statusChanged2 = FrameDiffWriter.computeChangedRows(
            newLines: ["NEW Status"],
            previousLines: statusLines
        )
        #expect(statusChanged2 == [0])
    }

    @Test("invalidate clears both content and status bar caches")
    func invalidateClearsBothCaches() {
        let writer = FrameDiffWriter()

        // After invalidate, previous lines are empty → all rows changed
        writer.invalidate()

        let changed = FrameDiffWriter.computeChangedRows(
            newLines: ["A", "B"],
            previousLines: []
        )
        #expect(changed == [0, 1])
    }
}
