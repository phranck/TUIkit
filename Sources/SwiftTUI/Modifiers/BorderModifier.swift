//
//  BorderModifier.swift
//  SwiftTUI
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

    /// The border style to use.
    let style: BorderStyle

    /// The color of the border (nil uses default terminal color).
    let color: Color?

    public var body: Never {
        fatalError("BorderedView renders via Renderable")
    }
}

// MARK: - Renderable

extension BorderedView: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Reduce available width for content by 2 (left + right border)
        var contentContext = context
        contentContext.availableWidth = max(1, context.availableWidth - 2)

        // Render content with reduced width
        let buffer = SwiftTUI.renderToBuffer(content, context: contentContext)

        guard !buffer.isEmpty else { return buffer }

        let contentWidth = buffer.width
        let innerWidth = max(contentWidth, 1)

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
        lines.append(colorize(topLine))

        // Content lines with side borders
        // Important: Reset ANSI before right border to prevent color bleeding
        let reset = "\u{1B}[0m"
        for line in buffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            let borderedLine = colorize(String(style.vertical))
                + paddedLine
                + reset  // Reset any styling from content
                + colorize(String(style.vertical))
            lines.append(borderedLine)
        }

        // Bottom border
        lines.append(colorize(bottomLine))

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

    /// Applies color to a string if a color is set.
    private func colorize(_ string: String) -> String {
        guard let color = color else { return string }
        var textStyle = TextStyle()
        textStyle.foregroundColor = color
        return ANSIRenderer.render(string, with: textStyle)
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
    ///     .border()
    ///
    /// Text("Rounded")
    ///     .border(.rounded, color: .cyan)
    ///
    /// Text("Double")
    ///     .border(.doubleLine, color: .yellow)
    /// ```
    ///
    /// - Parameters:
    ///   - style: The border style (default: .line).
    ///   - color: The border color (default: nil, uses terminal default).
    /// - Returns: A view with a border.
    public func border(
        _ style: BorderStyle = .line,
        color: Color? = nil
    ) -> some View {
        BorderedView(content: self, style: style, color: color)
    }
}

// MARK: - Legacy ViewModifier (kept for compatibility)

/// A modifier that adds a border around a view.
///
/// Note: This is the legacy implementation. The new `BorderedView`
/// correctly handles available width constraints.
public struct BorderModifier: ViewModifier {
    /// The border style to use.
    public let style: BorderStyle

    /// The color of the border (nil uses default terminal color).
    public let color: Color?

    public func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer {
        guard !buffer.isEmpty else { return buffer }

        let contentWidth = buffer.width
        let innerWidth = max(contentWidth, 1)

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
        lines.append(colorize(topLine))

        // Content lines with side borders
        // Important: Reset ANSI before right border to prevent color bleeding
        let reset = "\u{1B}[0m"
        for line in buffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            let borderedLine = colorize(String(style.vertical))
                + paddedLine
                + reset  // Reset any styling from content
                + colorize(String(style.vertical))
            lines.append(borderedLine)
        }

        // Bottom border
        lines.append(colorize(bottomLine))

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

    /// Applies color to a string if a color is set.
    private func colorize(_ string: String) -> String {
        guard let color = color else { return string }
        var textStyle = TextStyle()
        textStyle.foregroundColor = color
        return ANSIRenderer.render(string, with: textStyle)
    }
}
