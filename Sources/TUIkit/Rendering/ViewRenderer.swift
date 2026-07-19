//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewRenderer.swift
//
//  Created by LAYERED.work
//  License: MIT

/// Convenience class for standalone one-off view rendering.
///
/// `ViewRenderer` wraps the free function ``renderToBuffer(_:context:)``
/// with a complete one-pass runtime and terminal cursor positioning.
///
/// This class is **not** part of the main render pipeline. The main
/// pipeline is:
///
/// ```
/// AppRunner → RenderLoop.render() → renderToBuffer() → FrameDiffWriter → Terminal
/// ```
///
/// `ViewRenderer` is used by the ``renderOnce(_:)`` convenience API
/// for simple CLI tools that don't need a full ``App``. It shares the
/// runtime environment and render-pass lifecycle used by `RenderLoop`,
/// while intentionally omitting event-loop and diff-rendering behavior.
@MainActor
final class ViewRenderer {
    /// The terminal to render to.
    private let terminal: any TerminalProtocol

    /// Complete runtime used for the standalone render pass.
    private let tuiContext: TUIContext

    /// Creates a new ViewRenderer.
    ///
    /// - Parameters:
    ///   - terminal: The target terminal. Defaults to a production terminal.
    ///   - tuiContext: The runtime to use. Defaults to a production runtime.
    init(
        terminal: (any TerminalProtocol)? = nil,
        tuiContext: TUIContext? = nil
    ) {
        self.terminal = terminal ?? Terminal()
        self.tuiContext = tuiContext ?? TUIContext.production()
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
        render(atRow: row, column: column) {
            view
        }
    }

    /// Builds and renders a view inside a complete runtime render pass.
    ///
    /// Constructing the root while hydration is active lets root-level
    /// property wrappers bind to the same runtime as nested views.
    func render<V: View>(
        atRow row: Int = 1,
        column: Int = 1,
        @ViewBuilder content: () -> V
    ) {
        tuiContext.beginRenderPass()
        defer {
            tuiContext.focusManager.endRenderPass()
            tuiContext.endRenderPass()
        }

        let size = terminal.getSize()
        let rootIdentity = ViewIdentity(rootType: V.self)
        var context = RenderContext(
            availableWidth: size.width,
            availableHeight: size.height,
            tuiContext: tuiContext,
            identity: rootIdentity
        )
        context.hasExplicitWidth = true
        context.hasExplicitHeight = true
        let view = StateRegistration.withHydration(context: context) {
            content()
        }
        tuiContext.stateStorage.markActive(rootIdentity)
        let buffer = renderToBuffer(view, context: context)

        terminal.beginFrame()
        flush(buffer, atRow: row, column: column)
        terminal.endFrame()
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
