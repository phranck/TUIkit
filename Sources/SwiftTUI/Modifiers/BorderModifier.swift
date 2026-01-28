//
//  BorderModifier.swift
//  SwiftTUI
//
//  The .border() modifier for adding borders around views.
//

/// A modifier that adds a border around a view.
public struct BorderModifier: TViewModifier {
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
        for line in buffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            let borderedLine = colorize(String(style.vertical))
                + paddedLine
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
        var style = TextStyle()
        style.foregroundColor = color
        return ANSIRenderer.render(string, with: style)
    }
}

// MARK: - TView Extension

extension TView {
    /// Adds a border around this view.
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
    ) -> ModifiedView<Self, BorderModifier> {
        modifier(BorderModifier(style: style, color: color))
    }
}
