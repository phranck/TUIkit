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
/// ## Appearance
///
/// - **Standard**: Content line + thin divider (`─`), no background.
/// - **Block**: Content with `appHeaderBackground`, half-block divider.
///
/// ## Layout
///
/// ```
/// ┌──────────────────────────────────────────────────────────────────┐
/// │  My App Title                                   TUIkit v0.1.0   │
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
        let isBlock = context.environment.appearance.rawId == .block
        let palette = context.environment.palette

        if isBlock {
            return renderBlock(width: width, palette: palette)
        } else {
            return renderStandard(width: width, palette: palette)
        }
    }
}

// MARK: - Private Rendering

extension AppHeader {
    /// Renders the standard appearance: content + thin divider line.
    private func renderStandard(width: Int, palette: any Palette) -> FrameBuffer {
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

    /// Renders the block appearance: content with appHeaderBackground + block divider.
    private func renderBlock(width: Int, palette: any Palette) -> FrameBuffer {
        let headerBg = palette.appHeaderBackground
        var lines: [String] = []

        // Content lines with persistent background
        for line in contentBuffer.lines {
            let padded = line.padToVisibleWidth(width)
            let styled = ANSIRenderer.applyPersistentBackground(padded, color: headerBg)
            lines.append(styled)
        }

        // Block-style bottom divider (▀ in appHeaderBackground on app background)
        let divider = String(repeating: "▀", count: width)
        let styledDivider = ANSIRenderer.colorize(divider, foreground: headerBg)
        lines.append(styledDivider)

        return FrameBuffer(lines: lines)
    }
}
