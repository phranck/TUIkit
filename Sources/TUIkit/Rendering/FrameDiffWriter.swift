//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FrameDiffWriter.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0  only the lines that changed since the previous frame.
//

// MARK: - Frame Diff Writer

/// Compares rendered frames and writes only changed lines to the terminal.
///
/// `FrameDiffWriter` is the core of TUIKit's render optimization. Instead
/// of rewriting every terminal line on every frame, it stores the previous
/// frame's output and only writes lines that actually differ.
///
/// For a mostly-static UI (e.g. a menu with one animating spinner), this
/// reduces terminal writes from ~50 lines per frame to just 1–3 lines
/// (~94% reduction).
///
/// ## Usage
///
/// ```swift
/// let writer = FrameDiffWriter()
///
/// // Each frame:
/// let outputLines = writer.buildOutputLines(buffer: buffer, ...)
/// writer.writeContentDiff(newLines: outputLines, terminal: terminal, startRow: 1)
///
/// // On terminal resize:
/// writer.invalidate()
/// ```
final class FrameDiffWriter {
    /// The previous frame's content lines (terminal-ready strings with ANSI codes).
    private var previousContentLines: [String] = []

    /// The previous frame's status bar lines.
    private var previousStatusBarLines: [String] = []

    /// The previous frame's app header lines.
    private var previousAppHeaderLines: [String] = []
}

// MARK: - Internal API

extension FrameDiffWriter {
    /// Converts a ``FrameBuffer`` into terminal-ready output lines.
    ///
    /// Each output line includes background color, padding, and reset codes.
    /// Lines beyond the buffer's content are filled with background-colored spaces.
    /// This is a **pure function** — no side effects.
    ///
    /// - Parameters:
    ///   - buffer: The rendered frame buffer.
    ///   - terminalWidth: The terminal width in characters.
    ///   - terminalHeight: The number of rows to fill.
    ///   - bgCode: The ANSI background color code.
    ///   - reset: The ANSI reset code.
    /// - Returns: An array of terminal-ready strings, one per row.
    func buildOutputLines(
        buffer: FrameBuffer,
        terminalWidth: Int,
        terminalHeight: Int,
        bgCode: String,
        reset: String
    ) -> [String] {
        var lines: [String] = []
        lines.reserveCapacity(terminalHeight)

        let emptyLine = bgCode + String(repeating: " ", count: terminalWidth) + reset

        for row in 0..<terminalHeight {
            if row < buffer.height {
                let line = buffer.lines[row]
                let visibleWidth = line.strippedLength
                let padding = max(0, terminalWidth - visibleWidth)
                let lineWithBg = line.replacingOccurrences(of: reset, with: reset + bgCode)
                let paddedLine = bgCode + lineWithBg + String(repeating: " ", count: padding) + reset
                lines.append(paddedLine)
            } else {
                lines.append(emptyLine)
            }
        }

        return lines
    }

    /// Compares new content lines with the previous frame and writes only changed lines.
    func writeContentDiff(newLines: [String], terminal: Terminal, startRow: Int) {
        writeDiff(newLines: newLines, previousLines: previousContentLines, terminal: terminal, startRow: startRow)
        previousContentLines = newLines
    }

    /// Compares new status bar lines with the previous frame and writes only changed lines.
    func writeStatusBarDiff(newLines: [String], terminal: Terminal, startRow: Int) {
        writeDiff(newLines: newLines, previousLines: previousStatusBarLines, terminal: terminal, startRow: startRow)
        previousStatusBarLines = newLines
    }

    /// Compares new app header lines with the previous frame and writes only changed lines.
    func writeAppHeaderDiff(newLines: [String], terminal: Terminal, startRow: Int) {
        writeDiff(newLines: newLines, previousLines: previousAppHeaderLines, terminal: terminal, startRow: startRow)
        previousAppHeaderLines = newLines
    }

    /// Invalidates all cached previous frames, forcing a full repaint on the next render.
    func invalidate() {
        previousContentLines = []
        previousStatusBarLines = []
        previousAppHeaderLines = []
    }

    /// Computes which row indices have changed between two frames.
    ///
    /// Core diff algorithm, extracted as a static pure function for testability.
    static func computeChangedRows(newLines: [String], previousLines: [String]) -> [Int] {
        var changedRows: [Int] = []
        for row in 0..<newLines.count {
            if row >= previousLines.count || previousLines[row] != newLines[row] {
                changedRows.append(row)
            }
        }
        return changedRows
    }
}

// MARK: - Private Helpers

private extension FrameDiffWriter {
    /// Writes only the lines that differ between two frames.
    func writeDiff(newLines: [String], previousLines: [String], terminal: Terminal, startRow: Int) {
        let changedRows = Self.computeChangedRows(newLines: newLines, previousLines: previousLines)

        for row in changedRows {
            terminal.moveCursor(toRow: startRow + row, column: 1)
            terminal.write(newLines[row])
        }

        if previousLines.count > newLines.count {
            for row in newLines.count..<previousLines.count {
                terminal.moveCursor(toRow: startRow + row, column: 1)
                terminal.write(String(repeating: " ", count: previousLines[row].strippedLength))
            }
        }
    }
}
