//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AppHeader.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

// MARK: - App Header View

/// A header bar rendered at the top of the terminal, outside the view tree.
///
/// `AppHeader` is an internal view used by ``RenderLoop`` to render the
/// app header content. It renders the content buffer from ``AppHeaderState``
/// and appends a thin divider line below.
///
/// ## Layout
///
/// ```
/// ┌──────────────────────────────────────────────────────────────────┐
/// │ My App Title                                       TUIkit v0.1.0 │
/// │──────────────────────────────────────────────────────────────────│
/// ```
struct AppHeader: View {
    /// The pre-rendered content buffer from the modifier.
    let contentBuffer: FrameBuffer

    var body: Never {
        fatalError("AppHeader renders via Renderable")
    }
}

// MARK: - Renderable

extension AppHeader: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let width = context.availableWidth
        let palette = context.environment.palette
        var lines: [String] = []

        // Content lines padded to full width
        for line in contentBuffer.lines {
            lines.append(line.padToVisibleWidth(width))
        }

        // Thin divider line
        let divider = String(repeating: "─", count: width)
        let styledDivider = ANSIRenderer.colorize(divider, foreground: palette.border)
        lines.append(styledDivider)

        return FrameBuffer(lines: lines)
    }
}
