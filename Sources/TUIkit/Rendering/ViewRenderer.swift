//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewRenderer.swift
//
//  Created by LAYERED.work
//  License: MIT

/// Convenience class for standalone one-off view rendering.
///
/// `ViewRenderer` wraps the free function ``renderToBuffer(_:context:)``
/// with terminal cursor positioning. It is a thin wrapper — the actual
/// rendering dispatch happens in `renderToBuffer`, not here.
///
/// This class is **not** part of the main render pipeline. The main
/// pipeline is:
///
/// ```
/// AppRunner → RenderLoop.render() → renderToBuffer() → FrameDiffWriter → Terminal
/// ```
///
/// `ViewRenderer` is used by the ``renderOnce(_:)`` convenience API
/// for simple CLI tools that don't need a full ``App``. It bypasses
/// `RenderLoop`, `FrameDiffWriter`, environment, lifecycle tracking,
/// and diff-based rendering.
@MainActor
final class ViewRenderer {
    /// The terminal to render to.
    private let terminal: Terminal

    /// Creates a new ViewRenderer.
    ///
    /// - Parameter terminal: The target terminal (default: new Terminal instance).
    init(terminal: Terminal? = nil) {
        self.terminal = terminal ?? Terminal()
    }
}

// MARK: - Internal API

extension ViewRenderer {
    /// Renders a view to the terminal.
    ///
    /// Queries the terminal size, renders the view into a ``FrameBuffer``,
    /// and writes the result line-by-line to the terminal.
    ///
    /// - Parameters:
    ///   - view: The view to render.
    ///   - row: The starting row (1-based, default: 1).
    ///   - column: The starting column (1-based, default: 1).
    func render<V: View>(_ view: V, atRow row: Int = 1, column: Int = 1) {
        let size = terminal.getSize()
        let context = RenderContext(
            availableWidth: size.width,
            availableHeight: size.height
        )
        let buffer = renderToBuffer(view, context: context)
        flush(buffer, atRow: row, column: column)
    }
}

// MARK: - Private Helpers

private extension ViewRenderer {
    /// Flushes a FrameBuffer to the terminal at the specified position.
    func flush(_ buffer: FrameBuffer, atRow row: Int, column: Int) {
        for (index, line) in buffer.lines.enumerated() {
            terminal.moveCursor(toRow: row + index, column: column)
            terminal.write(line)
        }
    }
}
