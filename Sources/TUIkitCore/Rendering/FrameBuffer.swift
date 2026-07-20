//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FrameBuffer.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A 2D terminal-cell buffer that views render into before flushing.
///
/// `FrameBuffer` enables a two-pass rendering approach:
/// 1. Each view renders into its own buffer and measures its cell extent.
/// 2. Layout containers combine child buffers horizontally, vertically, or in layers.
/// 3. ANSI is encoded only when the final lines cross a terminal boundary.
///
/// The public ``lines`` property remains a compatibility adapter for pre-styled
/// strings. Internally the buffer owns grapheme clusters, wide-cell continuations,
/// normalized style state, and transparency explicitly.
///
/// - Important: This is framework infrastructure used as the rendering primitive in
///   ``ViewModifier/modify(buffer:context:)``. Most developers don't need to interact
///   with this type directly.
public struct FrameBuffer: Sendable, Equatable {
    private var surface: TerminalSurface
    private var isSynchronizingLines: Bool

    package var terminalSurface: TerminalSurface {
        get { surface }
        set {
            surface = newValue
            replaceLinesWithoutParsing(newValue.ansiEncodedLines)
        }
    }

    /// The terminal-safe, ANSI-encoded lines of rendered content.
    ///
    /// Reading this property returns the cached terminal-safe encoding. Assigning
    /// or mutating it reparses supported SGR style and neutralizes all other
    /// terminal control sequences.
    public var lines: [String] {
        didSet {
            guard !isSynchronizingLines else { return }
            surface = TerminalSurface(lines: lines)
            replaceLinesWithoutParsing(surface.ansiEncodedLines)
        }
    }

    /// The width of the buffer in terminal cells.
    public var width: Int {
        surface.width
    }

    /// The height of the buffer in terminal rows.
    public var height: Int {
        surface.height
    }

    /// Whether the buffer contains no explicit grapheme content.
    public var isEmpty: Bool {
        surface.isEmpty
    }

    /// Creates an empty buffer.
    public init() {
        surface = TerminalSurface()
        isSynchronizingLines = false
        lines = []
    }

    /// Creates a buffer from ANSI-styled or plain text lines.
    ///
    /// Only SGR styling is retained. Embedded cursor, device, hyperlink, and
    /// other control sequences are neutralized while parsing.
    ///
    /// - Parameter lines: The text lines to parse into terminal cells.
    public init(lines: [String]) {
        let surface = TerminalSurface(lines: lines)
        self.surface = surface
        self.isSynchronizingLines = false
        self.lines = surface.ansiEncodedLines
    }

    /// Creates a buffer with an already known cell extent.
    ///
    /// - Parameters:
    ///   - lines: The text lines to parse into terminal cells.
    ///   - width: The known minimum width of the buffer in terminal cells.
    public init(lines: [String], width: Int) {
        let surface = TerminalSurface(lines: lines, width: width)
        self.surface = surface
        self.isSynchronizingLines = false
        self.lines = surface.ansiEncodedLines
    }

    /// Creates a buffer containing a single line.
    ///
    /// - Parameter text: The text content to parse into terminal cells.
    public init(text: String) {
        let surface = TerminalSurface(lines: [text])
        self.surface = surface
        self.isSynchronizingLines = false
        self.lines = surface.ansiEncodedLines
    }

    /// Creates a spacer buffer with the specified height.
    ///
    /// A visible space on every row keeps the spacer distinct from an empty view.
    ///
    /// - Parameter height: The number of rows.
    public init(emptyWithHeight height: Int) {
        let surface = TerminalSurface(lines: Array(repeating: " ", count: max(0, height)))
        self.surface = surface
        self.isSynchronizingLines = false
        self.lines = surface.ansiEncodedLines
    }

    /// Creates a buffer of spaces with the specified dimensions.
    ///
    /// - Parameters:
    ///   - width: The width in terminal cells.
    ///   - height: The number of rows.
    public init(emptyWithWidth width: Int, height: Int) {
        let clampedWidth = max(0, width)
        let line = String(repeating: " ", count: clampedWidth)
        let surface = TerminalSurface(
            lines: Array(repeating: line, count: max(0, height)),
            width: clampedWidth
        )
        self.surface = surface
        self.isSynchronizingLines = false
        self.lines = surface.ansiEncodedLines
    }

    /// Creates a buffer by stacking all supplied buffers in one linear pass.
    ///
    /// - Parameter buffers: The buffers to stack vertically.
    public init(verticallyStacking buffers: [Self]) {
        let surface = TerminalSurface(verticallyStacking: buffers.map(\.surface))
        self.surface = surface
        self.isSynchronizingLines = false
        self.lines = surface.ansiEncodedLines
    }

    package init(terminalSurface: TerminalSurface) {
        self.surface = terminalSurface
        self.isSynchronizingLines = false
        self.lines = terminalSurface.ansiEncodedLines
    }
}

// MARK: - Public API

public extension FrameBuffer {
    /// Stacks another buffer below this one with optional spacing.
    ///
    /// - Parameters:
    ///   - other: The buffer to append below.
    ///   - spacing: Number of empty rows between the buffers.
    mutating func appendVertically(_ other: Self, spacing: Int = 0) {
        let spacing = max(0, spacing)
        let hadRows = !lines.isEmpty
        surface.appendVertically(other.surface, spacing: spacing)
        if !other.isEmpty {
            isSynchronizingLines = true
            if hadRows && spacing > 0 {
                lines.append(contentsOf: repeatElement("", count: spacing))
            }
            lines.append(contentsOf: other.lines)
            isSynchronizingLines = false
        }
    }

    /// Places another buffer to the right of this one with optional spacing.
    ///
    /// - Parameters:
    ///   - other: The buffer to append to the right.
    ///   - spacing: Number of cells between the buffers.
    mutating func appendHorizontally(_ other: Self, spacing: Int = 0) {
        surface.appendHorizontally(other.surface, spacing: max(0, spacing))
        replaceLinesWithoutParsing(surface.ansiEncodedLines)
    }

    /// Layers another buffer over this buffer at the top-leading origin.
    ///
    /// Transparent cells preserve the content below them. Styled spaces are
    /// explicit paint and therefore remain opaque.
    ///
    /// - Parameter overlay: The buffer to layer above this one.
    mutating func overlay(_ overlay: Self) {
        terminalSurface = surface.composited(with: overlay.surface, atX: 0, y: 0)
    }

    /// Creates a new buffer with another buffer composited at a cell position.
    ///
    /// Wide graphemes are replaced and clipped atomically, so an operation can
    /// never leave an orphan continuation cell.
    ///
    /// - Parameters:
    ///   - overlay: The buffer to composite on top.
    ///   - position: The zero-based cell and row offset for the overlay.
    /// - Returns: A new composited buffer.
    func composited(with overlay: Self, at position: (x: Int, y: Int)) -> Self {
        Self(
            terminalSurface: surface.composited(
                with: overlay.surface,
                atX: position.x,
                y: position.y
            )
        )
    }
}

// MARK: - Package Rendering API

extension FrameBuffer {
    package func clipped(toWidth width: Int, height: Int) -> Self {
        Self(terminalSurface: surface.clipped(toWidth: width, height: height))
    }
}

// MARK: - Storage Synchronization

private extension FrameBuffer {
    mutating func replaceLinesWithoutParsing(_ newLines: [String]) {
        isSynchronizingLines = true
        lines = newLines
        isSynchronizingLines = false
    }
}
