//
//  BorderModifier.swift
//  TUIKit
//
//  The .border() modifier for adding borders around views.
//

/// A view that wraps content with a border.
///
/// This modifier reduces the available width for content by 2 characters
/// (for the left and right border) to ensure the total width stays within bounds.
public struct BorderedView<Content: View>: View {
    /// The content to wrap with a border.
    let content: Content

    /// The border style to use (nil uses appearance default).
    let style: BorderStyle?

    /// The color of the border (nil uses theme border color).
    let color: Color?

    public var body: Never {
        fatalError("BorderedView renders via Renderable")
    }
}

// MARK: - Renderable

extension BorderedView: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Resolve border style - use explicit or fall back to appearance default
        let effectiveStyle = style ?? context.environment.appearance.borderStyle
        let isBlockAppearance = context.environment.appearance.id == .block
        
        // Reduce available width for content by 2 (left + right border)
        var contentContext = context
        contentContext.availableWidth = max(1, context.availableWidth - 2)

        // Render content with reduced width
        let buffer = TUIKit.renderToBuffer(content, context: contentContext)

        guard !buffer.isEmpty else { return buffer }

        let contentWidth = buffer.width
        let innerWidth = max(contentWidth, 1)
        
        if isBlockAppearance {
            return renderBlockStyle(buffer: buffer, innerWidth: innerWidth)
        } else {
            return renderStandardStyle(buffer: buffer, innerWidth: innerWidth, style: effectiveStyle)
        }
    }
    
    /// Renders with standard box-drawing characters.
    private func renderStandardStyle(buffer: FrameBuffer, innerWidth: Int, style: BorderStyle) -> FrameBuffer {
        let borderForeground = color ?? Color.theme.border

        // Build the top border line
        let topLine = buildBorderLine(
            left: style.topLeft,
            fill: style.horizontal,
            right: style.topRight,
            width: innerWidth
        )

        // Build the bottom border line
        let bottomLine = buildBorderLine(
            left: style.bottomLeft,
            fill: style.horizontal,
            right: style.bottomRight,
            width: innerWidth
        )

        // Build the result
        var lines: [String] = []

        // Top border
        lines.append(ANSIRenderer.colorize(topLine, foreground: borderForeground))

        // Content lines with side borders
        for line in buffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            let borderedLine = ANSIRenderer.colorize(String(style.vertical), foreground: borderForeground)
                + paddedLine
                + ANSIRenderer.reset
                + ANSIRenderer.colorize(String(style.vertical), foreground: borderForeground)
            lines.append(borderedLine)
        }

        // Bottom border
        lines.append(ANSIRenderer.colorize(bottomLine, foreground: borderForeground))

        return FrameBuffer(lines: lines)
    }
    
    /// Renders with half-block characters for block appearance.
    ///
    /// Block style design:
    /// ```
    /// ▄▄▄▄▄▄▄▄▄▄  ← Top: ▄, FG = container BG, BG = transparent
    /// █ Content █  ← Sides: █, FG = container BG, content has container BG
    /// ▀▀▀▀▀▀▀▀▀▀  ← Bottom: ▀, FG = container BG, BG = transparent
    /// ```
    private func renderBlockStyle(buffer: FrameBuffer, innerWidth: Int) -> FrameBuffer {
        var lines: [String] = []
        
        // For block style, use container background color for borders
        let containerBg = Color.theme.containerBackground
        let sideBorder = ANSIRenderer.colorize("█", foreground: containerBg)
        
        // Top border: ▄▄▄ with FG = container BG
        let topLine = String(repeating: "▄", count: innerWidth + 2)
        lines.append(ANSIRenderer.colorize(topLine, foreground: containerBg))
        
        // Content lines with █ side borders and container background
        for line in buffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            let styledContent = ANSIRenderer.applyPersistentBackground(paddedLine, color: containerBg)
            lines.append(sideBorder + styledContent + ANSIRenderer.reset + sideBorder)
        }
        
        // Bottom border: ▀▀▀ with FG = container BG
        let bottomLine = String(repeating: "▀", count: innerWidth + 2)
        lines.append(ANSIRenderer.colorize(bottomLine, foreground: containerBg))
        
        return FrameBuffer(lines: lines)
    }

    /// Builds a horizontal border line.
    private func buildBorderLine(
        left: Character,
        fill: Character,
        right: Character,
        width: Int
    ) -> String {
        String(left) + String(repeating: fill, count: width) + String(right)
    }
}

// MARK: - View Extension

extension View {
    /// Adds a border around this view.
    ///
    /// The border reserves 2 characters of width (left and right),
    /// so the content is rendered with reduced available width.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Hello")
    ///     .border()  // Uses appearance.borderStyle
    ///
    /// Text("Rounded")
    ///     .border(.rounded, color: .cyan)
    ///
    /// Text("Double")
    ///     .border(.doubleLine, color: .yellow)
    /// ```
    ///
    /// - Parameters:
    ///   - style: The border style (default: appearance borderStyle).
    ///   - color: The border color (default: theme border color).
    /// - Returns: A view with a border.
    public func border(
        _ style: BorderStyle? = nil,
        color: Color? = nil
    ) -> some View {
        BorderedView(content: self, style: style, color: color)
    }
}


