//
//  Panel.swift
//  TUIKit
//
//  A titled container view with a header.
//

/// A bordered container with a title in the top border.
///
/// `Panel` is useful for grouping content with a visible label,
/// similar to a fieldset in HTML or a group box in desktop UIs.
///
/// # Example
///
/// ```swift
/// Panel("Settings") {
///     Text("Option 1")
///     Text("Option 2")
/// }
///
/// Panel("User Info", borderStyle: .doubleLine, titleColor: .cyan) {
///     Text("Name: John")
///     Text("Age: 30")
/// }
/// ```
public struct Panel<Content: View>: View {
    /// The title displayed in the top border.
    public let title: String

    /// The content of the panel.
    public let content: Content

    /// The border style (nil uses appearance default).
    public let borderStyle: BorderStyle?

    /// The border color.
    public let borderColor: Color?

    /// The title color.
    public let titleColor: Color?

    /// The padding inside the panel.
    public let padding: EdgeInsets

    /// Creates a panel with the specified options.
    ///
    /// - Parameters:
    ///   - title: The title to display in the top border.
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - borderColor: The border color (default: theme border).
    ///   - titleColor: The title color (default: same as border).
    ///   - padding: The inner padding (default: horizontal 1, vertical 0).
    ///   - content: The content of the panel.
    public init(
        _ title: String,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(horizontal: 1, vertical: 0),
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
        self.borderStyle = borderStyle
        self.borderColor = borderColor
        self.titleColor = titleColor
        self.padding = padding
    }

    public var body: Never {
        fatalError("Panel renders via Renderable")
    }
}

// MARK: - Panel Rendering

extension Panel: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Resolve border style - use explicit or fall back to appearance default
        let effectiveBorderStyle = borderStyle ?? context.environment.appearance.borderStyle
        
        // Render the content first
        let paddedContent = content.padding(padding)
        let contentBuffer = TUIKit.renderToBuffer(paddedContent, context: context)

        guard !contentBuffer.isEmpty else {
            return FrameBuffer()
        }

        // Title with spaces: " Title "
        let titleText = " \(title) "
        let titleLength = titleText.count

        // Inner width must fit both content and title (plus corner + one horizontal on each side)
        // Top line structure: ┌─ Title ─────┐
        // So minimum inner width = titleLength + 2 (for the ─ on each side of title)
        let innerWidth = max(contentBuffer.width, titleLength + 2)

        // Build top border with title
        // Format: ┌─ Title ─────┐
        let titleStyled = colorize(titleText, with: titleColor ?? borderColor)

        // Left part: corner + one horizontal
        let leftPart = colorize(
            String(effectiveBorderStyle.topLeft) + String(effectiveBorderStyle.horizontal),
            with: borderColor
        )

        // Right part: remaining horizontals + corner
        // Total top line width (excluding corners) = innerWidth
        // Used by: 1 (left horizontal) + titleLength + rightPartLength = innerWidth
        let rightPartLength = max(0, innerWidth - 1 - titleLength)
        let rightPart = colorize(
            String(repeating: effectiveBorderStyle.horizontal, count: rightPartLength) + String(effectiveBorderStyle.topRight),
            with: borderColor
        )

        let topLine = leftPart + titleStyled + rightPart

        // Build bottom border (innerWidth horizontals between corners)
        let bottomLine = colorize(
            String(effectiveBorderStyle.bottomLeft)
                + String(repeating: effectiveBorderStyle.horizontal, count: innerWidth)
                + String(effectiveBorderStyle.bottomRight),
            with: borderColor
        )

        // Build result
        var lines: [String] = []
        lines.append(topLine)

        // Content lines with side borders
        // Important: Add reset before right border to prevent color bleeding
        let reset = "\u{1B}[0m"
        let leftBorder = colorize(String(effectiveBorderStyle.vertical), with: borderColor)
        let rightBorder = colorize(String(effectiveBorderStyle.vertical), with: borderColor)

        for line in contentBuffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            lines.append(leftBorder + paddedLine + reset + rightBorder)
        }

        lines.append(bottomLine)

        return FrameBuffer(lines: lines)
    }

    /// Applies color to a string, using theme border color as default.
    private func colorize(_ string: String, with color: Color?) -> String {
        var style = TextStyle()
        style.foregroundColor = color ?? Color.theme.border
        return ANSIRenderer.render(string, with: style)
    }
}
