//
//  FrameDiffWriter.swift
//  TUIkit
//
//  Converts FrameBuffers to terminal-ready output lines and writes
//  only the lines that changed since the previous frame.
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
/// writer.writeDiff(newLines: outputLines, terminal: terminal, startRow: 1)
///
/// // On terminal resize:
/// writer.invalidate()
/// ```
final class FrameDiffWriter {
    /// The previous frame's content lines (terminal-ready strings with ANSI codes).
    private var previousContentLines: [String] = []

    /// The previous frame's status bar lines.
    private var previousStatusBarLines: [String] = []

    // MARK: - Output Line Building

    /// Converts a ``FrameBuffer`` into terminal-ready output lines.
    ///
    /// Each output line includes:
    /// - Background color applied through ANSI reset codes
    /// - Padding to fill the terminal width
    /// - Reset code at the end
    ///
    /// Lines beyond the buffer's content are filled with background-colored
    /// spaces. The returned array always has exactly `terminalHeight` entries.
    ///
    /// This is a **pure function** — it has no side effects and produces
    /// the same output for the same inputs.
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
            if row < buffer.lines.count {
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

    // MARK: - Diff Writing

    /// Compares new content lines with the previous frame and writes only
    /// the lines that changed.
    ///
    /// On the first call (or after ``invalidate()``), all lines are written.
    /// On subsequent calls, only lines that differ from the previous frame
    /// are written to the terminal, significantly reducing I/O overhead.
    ///
    /// - Parameters:
    ///   - newLines: The current frame's terminal-ready output lines.
    ///   - terminal: The terminal to write to.
    ///   - startRow: The 1-based terminal row where output begins.
    func writeContentDiff(
        newLines: [String],
        terminal: Terminal,
        startRow: Int
    ) {
        writeDiff(
            newLines: newLines,
            previousLines: previousContentLines,
            terminal: terminal,
            startRow: startRow
        )
        previousContentLines = newLines
    }

    /// Compares new status bar lines with the previous frame and writes
    /// only the lines that changed.
    ///
    /// - Parameters:
    ///   - newLines: The current frame's status bar output lines.
    ///   - terminal: The terminal to write to.
    ///   - startRow: The 1-based terminal row where the status bar begins.
    func writeStatusBarDiff(
        newLines: [String],
        terminal: Terminal,
        startRow: Int
    ) {
        writeDiff(
            newLines: newLines,
            previousLines: previousStatusBarLines,
            terminal: terminal,
            startRow: startRow
        )
        previousStatusBarLines = newLines
    }

    /// Invalidates all cached previous frames, forcing a full repaint
    /// on the next render.
    ///
    /// Call this when the terminal is resized (SIGWINCH) to ensure every
    /// line is rewritten with the new dimensions.
    func invalidate() {
        previousContentLines = []
        previousStatusBarLines = []
    }

    // MARK: - Diff Computation

    /// Computes which row indices have changed between two frames.
    ///
    /// This is the core diff algorithm, extracted as a static pure function
    /// for testability. Returns the indices of all rows in `newLines` that
    /// differ from `previousLines` (or that are new because `newLines`
    /// is longer).
    ///
    /// - Parameters:
    ///   - newLines: The current frame's lines.
    ///   - previousLines: The previous frame's lines.
    /// - Returns: An array of 0-based row indices that need to be rewritten.
    static func computeChangedRows(
        newLines: [String],
        previousLines: [String]
    ) -> [Int] {
        var changedRows: [Int] = []
        for row in 0..<newLines.count {
            if row >= previousLines.count || previousLines[row] != newLines[row] {
                changedRows.append(row)
            }
        }
        return changedRows
    }

    // MARK: - Private

    /// Compares two line arrays and writes only the differing lines.
    ///
    /// - Parameters:
    ///   - newLines: The current frame's lines.
    ///   - previousLines: The previous frame's lines.
    ///   - terminal: The terminal to write to.
    ///   - startRow: The 1-based terminal row offset.
    private func writeDiff(
        newLines: [String],
        previousLines: [String],
        terminal: Terminal,
        startRow: Int
    ) {
        for row in 0..<newLines.count {
            let newLine = newLines[row]

            // Skip if the line is identical to the previous frame
            if row < previousLines.count && previousLines[row] == newLine {
                continue
            }

            terminal.moveCursor(toRow: startRow + row, column: 1)
            terminal.write(newLine)
        }

        // If previous frame had more lines, clear the extra ones
        // (e.g. after terminal resize to smaller height)
        if previousLines.count > newLines.count {
            for row in newLines.count..<previousLines.count {
                terminal.moveCursor(toRow: startRow + row, column: 1)
                terminal.write(String(repeating: " ", count: previousLines[row].strippedLength))
            }
        }
    }
}
