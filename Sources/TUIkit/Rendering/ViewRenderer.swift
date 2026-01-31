//
//  ViewRenderer.swift
//  TUIkit
//
//  Renders Views to terminal output via FrameBuffer.
//

import Foundation

/// Convenience class for standalone view rendering.
///
/// `ViewRenderer` wraps the free function ``renderToBuffer(_:context:)``
/// with terminal cursor positioning. It is a thin wrapper — the actual
/// rendering dispatch happens in `renderToBuffer`, not here.
///
/// The main app uses `RenderLoop` instead, which owns the full
/// pipeline (environment assembly, lifecycle, status bar). Use
/// `ViewRenderer` for one-off rendering outside the main loop.
public final class ViewRenderer {
    /// The terminal to render to.
    private let terminal: Terminal

    /// Creates a new ViewRenderer.
    ///
    /// - Parameter terminal: The target terminal.
    public init(terminal: Terminal = Terminal()) {
        self.terminal = terminal
    }

    /// Renders a view to the terminal.
    ///
    /// - Parameters:
    ///   - view: The view to render.
    ///   - row: The starting row (1-based, default: 1).
    ///   - column: The starting column (1-based, default: 1).
    public func render<V: View>(_ view: V, atRow row: Int = 1, column: Int = 1) {
        let context = RenderContext(terminal: terminal)
        let buffer = renderToBuffer(view, context: context)
        flush(buffer, atRow: row, column: column)
    }

    /// Flushes a FrameBuffer to the terminal at the specified position.
    private func flush(_ buffer: FrameBuffer, atRow row: Int, column: Int) {
        for (index, line) in buffer.lines.enumerated() {
            terminal.moveCursor(toRow: row + index, column: column)
            terminal.write(line)
        }
    }
}

// MARK: - Child Info

/// Describes a child view within a stack for layout purposes.
struct ChildInfo {
    /// The rendered buffer of this child (nil for spacers, computed later).
    let buffer: FrameBuffer?

    /// Whether this child is a Spacer.
    let isSpacer: Bool

    /// The minimum length of this spacer (only relevant if isSpacer is true).
    let spacerMinLength: Int?
}

// MARK: - Child Info Provider

/// Internal protocol that allows stack containers to extract individual
/// child info from their content (which is typically a TupleView).
protocol ChildInfoProvider {
    /// Returns an array of ChildInfo, one per child view.
    func childInfos(context: RenderContext) -> [ChildInfo]
}

/// Creates a ChildInfo for a single view.
func makeChildInfo<V: View>(for view: V, context: RenderContext) -> ChildInfo {
    if let spacer = view as? Spacer {
        return ChildInfo(buffer: nil, isSpacer: true, spacerMinLength: spacer.minLength)
    }
    return ChildInfo(
        buffer: renderToBuffer(view, context: context),
        isSpacer: false,
        spacerMinLength: nil
    )
}

// MARK: - Child Info Resolution

/// Resolves child infos from a view's content.
///
/// If the content conforms to `ChildInfoProvider` (e.g. TupleViews),
/// it returns individual child infos. Otherwise it returns the content
/// as a single-element array.
///
/// - Parameters:
///   - content: The content view.
///   - context: The rendering context.
/// - Returns: An array of ChildInfo.
func resolveChildInfos<V: View>(from content: V, context: RenderContext) -> [ChildInfo] {
    if let provider = content as? ChildInfoProvider {
        return provider.childInfos(context: context)
    }
    return [makeChildInfo(for: content, context: context)]
}
