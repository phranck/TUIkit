//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FrameBuffer.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A 2D text buffer that views render into before flushing to the terminal.
///
/// `FrameBuffer` enables a two-pass rendering approach:
/// 1. Each view renders into its own buffer (measuring its size)
/// 2. Layout containers combine child buffers (horizontally, vertically, or layered)
/// 3. The final root buffer is flushed to the terminal
///
/// Each line in the buffer is a string that may contain ANSI escape codes.
///
/// - Important: This is framework infrastructure used as the rendering primitive in
///   ``ViewModifier/modify(buffer:context:)``. Most developers don't need to interact
///   with this type directly.
public struct FrameBuffer: Sendable, Equatable {
    /// The lines of rendered content (may contain ANSI escape codes).
    ///
    /// Mutating `lines` directly recomputes the cached ``width``.
    public var lines: [String] {
        didSet { recomputeWidth() }
    }

    /// The width of the buffer (the length of the longest line in visible characters).
    ///
    /// This is a stored property, recomputed automatically whenever
    /// ``lines`` is mutated. Accessing `width` is O(1) — the expensive
    /// ANSI-stripping regex runs only once per mutation, not per access.
    public private(set) var width: Int

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
        self.width = 0
    }

    /// Creates a buffer from an array of lines.
    ///
    /// - Parameter lines: The text lines.
    public init(lines: [String]) {
        self.lines = lines
        self.width = Self.computeWidth(lines)
    }

    /// Initializer that accepts pre-computed width.
    ///
    /// Use this when the width is already known to avoid redundant computation.
    public init(lines: [String], width: Int) {
        self.lines = lines
        self.width = width
    }

    /// Creates a buffer containing a single line.
    ///
    /// - Parameter text: The text content.
    public init(text: String) {
        self.lines = [text]
        self.width = text.strippedLength
    }

    /// Creates a spacer buffer with the specified height.
    ///
    /// The buffer contains lines with a single space character to ensure
    /// it is not considered "empty" by layout algorithms. This is important
    /// for Spacer views which need to occupy vertical space even without
    /// visible content.
    ///
    /// - Parameter height: The number of lines.
    public init(emptyWithHeight height: Int) {
        // Use a single space instead of empty string so the buffer
        // is not considered "empty" by appendVertically
        self.lines = Array(repeating: " ", count: height)
        self.width = 1
    }

    /// Creates a buffer of empty spaces with the specified width and height.
    ///
    /// Used by horizontal stacks for Spacer views which need to occupy
    /// horizontal space across multiple rows.
    ///
    /// - Parameters:
    ///   - width: The width in characters.
    ///   - height: The number of lines.
    public init(emptyWithWidth width: Int, height: Int) {
        self.lines = Array(repeating: String(repeating: " ", count: width), count: height)
        self.width = width
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

// MARK: - Public API

public extension FrameBuffer {
    /// Stacks another buffer below this one with optional spacing.
    ///
    /// - Parameters:
    ///   - other: The buffer to append below.
    ///   - spacing: Number of empty lines between the two buffers.
    mutating func appendVertically(_ other: Self, spacing: Int = 0) {
        guard !other.isEmpty else { return }

        // Pre-compute the new width (avoids redundant computation in didSet)
        let newWidth = max(width, other.width)

        // Build combined array
        var combined = lines
        if !combined.isEmpty && spacing > 0 {
            combined.append(contentsOf: repeatElement("", count: spacing))
        }
        combined.append(contentsOf: other.lines)

        // Replace self with new buffer using pre-computed width
        self = FrameBuffer(lines: combined, width: newWidth)
    }

    /// Places another buffer to the right of this one with optional spacing.
    ///
    /// - Parameters:
    ///   - other: The buffer to append to the right.
    ///   - spacing: Number of space characters between the two buffers.
    mutating func appendHorizontally(_ other: Self, spacing: Int = 0) {
        let maxHeight = max(height, other.height)
        let myWidth = width
        let spacer = String(repeating: " ", count: spacing)

        // Pre-compute the new width
        let newWidth = myWidth + spacing + other.width

        var result: [String] = []
        result.reserveCapacity(maxHeight)

        for row in 0..<maxHeight {
            let left = row < lines.count ? lines[row] : ""
            let right = row < other.lines.count ? other.lines[row] : ""

            // Pad the left side to consistent visible width
            let leftPadded = left.padToVisibleWidth(myWidth)
            result.append(leftPadded + spacer + right)
        }

        // Replace self with new buffer using pre-computed width
        self = FrameBuffer(lines: result, width: newWidth)
    }

    /// Layers another buffer on top of this one (ZStack behavior).
    ///
    /// Non-empty characters in the overlay replace characters in the base.
    /// For simplicity, this just overlays line by line.
    ///
    /// - Parameter overlay: The buffer to overlay on top.
    mutating func overlay(_ overlay: Self) {
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
    func composited(with overlay: Self, at position: (x: Int, y: Int)) -> Self {
        guard !overlay.isEmpty else { return self }

        let resultWidth = max(width, position.x + overlay.width)
        let resultHeight = max(height, position.y + overlay.height)

        var result: [String] = []

        for row in 0..<resultHeight {
            // Keep the original (unpadded) line for ANSI state extraction.
            // padToVisibleWidth appends unstyled spaces that lose the base's
            // ANSI state, so insertOverlay needs the original to restore it.
            let originalLine: String? = row < lines.count ? lines[row] : nil
            var baseLine: String
            if let original = originalLine {
                baseLine = original.padToVisibleWidth(resultWidth)
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
                        atColumn: position.x,
                        originalBase: originalLine
                    )
                }
            }

            result.append(baseLine)
        }

        return Self(lines: result)
    }
}

// MARK: - Private Helpers

private extension FrameBuffer {

    /// ANSI SGR reset sequence. Inlined to avoid depending on ANSIRenderer.
    static let ansiReset = "\u{1B}[0m"
    /// Recomputes the cached ``width`` from the current ``lines``.
    ///
    /// Called automatically by the `didSet` observer on ``lines``.
    mutating func recomputeWidth() {
        width = Self.computeWidth(lines)
    }

    /// Computes the visible width of a set of lines.
    ///
    /// - Parameter lines: The lines to measure.
    /// - Returns: The length of the longest line in visible characters.
    static func computeWidth(_ lines: [String]) -> Int {
        lines.map { $0.strippedLength }.max() ?? 0
    }

    /// Inserts overlay text into base text at the specified column position.
    ///
    /// Splits the base line at visible-character boundaries (ignoring ANSI codes)
    /// and preserves the base's ANSI styling in the prefix and suffix regions.
    /// The overlay replaces the base in its column range, with its own styling intact.
    ///
    /// After the overlay, the base's active ANSI state is restored before the
    /// suffix so the dimmed background (or any other base styling) continues
    /// seamlessly to the right of the overlay.
    ///
    /// - Parameters:
    ///   - base: The base text line (may contain ANSI codes).
    ///   - overlay: The overlay text to insert (may contain ANSI codes).
    ///   - column: The column position (0-based, in visible characters).
    ///   - originalBase: The original base line before padding, used to extract
    ///     the active ANSI state. If `nil`, the state is extracted from `base`.
    /// - Returns: The composited line with base styling preserved around the overlay.
    func insertOverlay(
        base: String,
        overlay: String,
        atColumn column: Int,
        originalBase: String? = nil
    ) -> String {
        let overlayVisibleWidth = overlay.strippedLength
        let afterOverlayColumn = column + overlayVisibleWidth

        // Split the base into prefix (before overlay) and suffix (after overlay),
        // preserving all ANSI codes in both segments.
        let prefix = base.ansiAwarePrefix(visibleCount: column)
        let suffix = base.ansiAwareSuffix(droppingVisible: afterOverlayColumn)

        // Extract the leading ANSI state from the original (unpadded) base line.
        // The leading sequences contain the full styling setup (BG + FG + dim)
        // before any visible text. This is more reliable than scanning the whole
        // string, because applyPersistentBackground appends a lone BG code after
        // the final reset that doesn't represent the full styling state.
        let styleSource = originalBase ?? base
        let baseStyle = styleSource.leadingANSISequences()

        // Build: [prefix] + [reset] + [overlay] + [reset + base style restore] + [suffix]
        var result = prefix
        result += Self.ansiReset
        result += overlay
        result += Self.ansiReset
        result += baseStyle
        result += suffix

        return result
    }
}
