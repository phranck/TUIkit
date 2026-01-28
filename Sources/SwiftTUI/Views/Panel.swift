//
//  Panel.swift
//  SwiftTUI
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
public struct Panel<Content: TView>: TView {
    /// The title displayed in the top border.
    public let title: String

    /// The content of the panel.
    public let content: Content

    /// The border style.
    public let borderStyle: BorderStyle

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
    ///   - borderStyle: The border style (default: .line).
    ///   - borderColor: The border color (default: nil).
    ///   - titleColor: The title color (default: nil, same as border).
    ///   - padding: The inner padding (default: horizontal 1, vertical 0).
    ///   - content: The content of the panel.
    public init(
        _ title: String,
        borderStyle: BorderStyle = .line,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(horizontal: 1, vertical: 0),
        @TViewBuilder content: () -> Content
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
        // Render the content first
        let paddedContent = content.padding(padding)
        let contentBuffer = SwiftTUI.renderToBuffer(paddedContent, context: context)

        guard !contentBuffer.isEmpty else {
            return FrameBuffer()
        }

        let innerWidth = max(contentBuffer.width, title.count + 4)
        
        // Build top border with title
        // Format: ┌─ Title ─────┐
        let titleText = " \(title) "
        let titleStyled = colorize(titleText, with: titleColor ?? borderColor)
        
        let leftPart = colorize(
            String(borderStyle.topLeft) + String(borderStyle.horizontal),
            with: borderColor
        )
        let rightPartLength = max(0, innerWidth - 2 - title.count - 2)
        let rightPart = colorize(
            String(repeating: borderStyle.horizontal, count: rightPartLength) + String(borderStyle.topRight),
            with: borderColor
        )
        let topLine = leftPart + titleStyled + rightPart

        // Build bottom border
        let bottomLine = colorize(
            String(borderStyle.bottomLeft)
                + String(repeating: borderStyle.horizontal, count: innerWidth)
                + String(borderStyle.bottomRight),
            with: borderColor
        )

        // Build result
        var lines: [String] = []
        lines.append(topLine)

        // Content lines with side borders
        let leftBorder = colorize(String(borderStyle.vertical), with: borderColor)
        let rightBorder = colorize(String(borderStyle.vertical), with: borderColor)

        for line in contentBuffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            lines.append(leftBorder + paddedLine + rightBorder)
        }

        lines.append(bottomLine)

        return FrameBuffer(lines: lines)
    }

    /// Applies color to a string if a color is set.
    private func colorize(_ string: String, with color: Color?) -> String {
        guard let color = color else { return string }
        var style = TextStyle()
        style.foregroundColor = color
        return ANSIRenderer.render(string, with: style)
    }
}
