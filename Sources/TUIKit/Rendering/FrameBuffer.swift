//
//  FrameBuffer.swift
//  TUIKit
//
//  A 2D text buffer for off-screen rendering before terminal output.
//

/// A 2D text buffer that views render into before flushing to the terminal.
///
/// `FrameBuffer` enables a two-pass rendering approach:
/// 1. Each view renders into its own buffer (measuring its size)
/// 2. Layout containers combine child buffers (horizontally, vertically, or layered)
/// 3. The final root buffer is flushed to the terminal
///
/// Each line in the buffer is a string that may contain ANSI escape codes.
public struct FrameBuffer {
    /// The lines of rendered content (may contain ANSI escape codes).
    public var lines: [String]

    /// The width of the buffer (the length of the longest line in visible characters).
    public var width: Int {
        lines.map { $0.strippedLength }.max() ?? 0
    }

    /// The height of the buffer (number of lines).
    public var height: Int {
        lines.count
    }

    /// Whether the buffer is empty.
    public var isEmpty: Bool {
        lines.isEmpty || lines.allSatisfy { $0.isEmpty }
    }

    /// Creates an empty buffer.
    public init() {
        self.lines = []
    }

    /// Creates a buffer from an array of lines.
    ///
    /// - Parameter lines: The text lines.
    public init(lines: [String]) {
        self.lines = lines
    }

    /// Creates a buffer containing a single line.
    ///
    /// - Parameter text: The text content.
    public init(text: String) {
        self.lines = [text]
    }

    /// Creates an empty buffer with the specified height.
    ///
    /// - Parameter height: The number of empty lines.
    public init(emptyWithHeight height: Int) {
        self.lines = Array(repeating: "", count: height)
    }

    // MARK: - Combining Buffers

    /// Stacks another buffer below this one with optional spacing.
    ///
    /// - Parameters:
    ///   - other: The buffer to append below.
    ///   - spacing: Number of empty lines between the two buffers.
    public mutating func appendVertically(_ other: Self, spacing: Int = 0) {
        if !lines.isEmpty && !other.isEmpty && spacing > 0 {
            lines.append(contentsOf: Array(repeating: "", count: spacing))
        }
        lines.append(contentsOf: other.lines)
    }

    /// Places another buffer to the right of this one with optional spacing.
    ///
    /// - Parameters:
    ///   - other: The buffer to append to the right.
    ///   - spacing: Number of space characters between the two buffers.
    public mutating func appendHorizontally(_ other: Self, spacing: Int = 0) {
        let maxHeight = max(height, other.height)
        let myWidth = width
        let spacer = String(repeating: " ", count: spacing)

        var result: [String] = []
        for row in 0..<maxHeight {
            let left = row < lines.count ? lines[row] : ""
            let right = row < other.lines.count ? other.lines[row] : ""

            // Pad the left side to consistent visible width
            let leftPadded = left.padToVisibleWidth(myWidth)
            result.append(leftPadded + spacer + right)
        }
        lines = result
    }

    /// Layers another buffer on top of this one (ZStack behavior).
    ///
    /// Non-empty characters in the overlay replace characters in the base.
    /// For simplicity, this just overlays line by line.
    ///
    /// - Parameter overlay: The buffer to overlay on top.
    public mutating func overlay(_ overlay: Self) {
        let maxHeight = max(height, overlay.height)
        var result: [String] = []
        for row in 0..<maxHeight {
            if row < overlay.lines.count && !overlay.lines[row].isEmpty {
                result.append(overlay.lines[row])
            } else if row < lines.count {
                result.append(lines[row])
            } else {
                result.append("")
            }
        }
        lines = result
    }

    /// Creates a new buffer with another buffer composited on top at the specified position.
    ///
    /// This performs character-level compositing: overlay characters replace base characters
    /// only where the overlay has visible content (non-space characters).
    ///
    /// - Parameters:
    ///   - overlay: The buffer to composite on top.
    ///   - position: The (x, y) offset where the overlay should be placed.
    /// - Returns: A new buffer with the overlay composited.
    public func composited(with overlay: Self, at position: (x: Int, y: Int)) -> Self {
        guard !overlay.isEmpty else { return self }

        let resultWidth = max(width, position.x + overlay.width)
        let resultHeight = max(height, position.y + overlay.height)

        var result: [String] = []

        for row in 0..<resultHeight {
            // Get the base line (padded to result width)
            var baseLine: String
            if row < lines.count {
                baseLine = lines[row].padToVisibleWidth(resultWidth)
            } else {
                baseLine = String(repeating: " ", count: resultWidth)
            }

            // Check if this row has overlay content
            let overlayRow = row - position.y
            if overlayRow >= 0 && overlayRow < overlay.lines.count {
                let overlayLine = overlay.lines[overlayRow]
                if !overlayLine.isEmpty {
                    // Insert overlay content at the x position
                    baseLine = insertOverlay(
                        base: baseLine,
                        overlay: overlayLine,
                        atColumn: position.x
                    )
                }
            }

            result.append(baseLine)
        }

        return Self(lines: result)
    }

    /// Inserts overlay text into base text at the specified column position.
    ///
    /// - Parameters:
    ///   - base: The base text line.
    ///   - overlay: The overlay text to insert.
    ///   - column: The column position (0-based).
    /// - Returns: The composited line.
    private func insertOverlay(base: String, overlay: String, atColumn column: Int) -> String {
        // Strip ANSI codes from the base to get accurate column positions.
        // Without stripping, escape sequences would shift character offsets.
        // The overlay keeps its ANSI codes intact so its styling is preserved.
        let baseChars = Array(base.stripped)
        let overlayStripped = overlay.stripped

        // Build: [base prefix] + [overlay with ANSI] + [base suffix]
        var result = ""

        // Base characters before the overlay insertion point
        if column > 0 {
            let prefixEnd = min(column, baseChars.count)
            result += String(baseChars[0..<prefixEnd])
            if prefixEnd < column {
                result += String(repeating: " ", count: column - prefixEnd)
            }
        }

        // Overlay with its ANSI styling intact
        result += overlay

        // Remaining base characters after the overlay region
        let afterOverlayColumn = column + overlayStripped.count
        if afterOverlayColumn < baseChars.count {
            result += String(baseChars[afterOverlayColumn...])
        }

        return result
    }

    // MARK: - Combining Arrays

    /// Creates a vertically stacked buffer from an array of buffers.
    ///
    /// TupleViews use this to combine their children vertically by default
    /// (the parent stack then decides the actual layout direction).
    ///
    /// - Parameter buffers: The buffers to stack vertically.
    public init(verticallyStacking buffers: [Self]) {
        self.init()
        for buffer in buffers {
            appendVertically(buffer)
        }
    }
}
