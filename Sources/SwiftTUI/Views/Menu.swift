//
//  Menu.swift
//  SwiftTUI
//
//  A menu view that displays a list of selectable items.
//

/// A menu item representing a single selectable option.
public struct MenuItem: Identifiable {
    /// The unique identifier.
    public let id: String

    /// The display label.
    public let label: String

    /// An optional keyboard shortcut (e.g., "1", "a", "q").
    public let shortcut: Character?

    /// Creates a menu item.
    ///
    /// - Parameters:
    ///   - id: The unique identifier (defaults to label).
    ///   - label: The display label.
    ///   - shortcut: An optional keyboard shortcut character.
    public init(id: String? = nil, label: String, shortcut: Character? = nil) {
        self.id = id ?? label
        self.label = label
        self.shortcut = shortcut
    }
}

/// A vertical menu displaying a list of selectable items.
///
/// `Menu` renders items as a vertical list with optional shortcuts.
/// The currently selected item is highlighted. Since SwiftTUI doesn't
/// have state management yet, selection is passed in as a parameter.
///
/// # Example
///
/// ```swift
/// Menu(
///     title: "Main Menu",
///     items: [
///         MenuItem(label: "Text Styles", shortcut: "1"),
///         MenuItem(label: "Colors", shortcut: "2"),
///         MenuItem(label: "Containers", shortcut: "3"),
///         MenuItem(label: "Quit", shortcut: "q")
///     ],
///     selectedIndex: 0
/// )
/// ```
public struct Menu: TView {
    /// The menu title (optional).
    public let title: String?

    /// The menu items.
    public let items: [MenuItem]

    /// The currently selected item index.
    public let selectedIndex: Int

    /// The style for unselected items.
    public let itemColor: Color?

    /// The style for the selected item.
    public let selectedColor: Color?

    /// The indicator for the selected item.
    public let selectionIndicator: String

    /// The border style (nil for no border).
    public let borderStyle: BorderStyle?

    /// The border color.
    public let borderColor: Color?

    /// Creates a menu with the specified options.
    ///
    /// - Parameters:
    ///   - title: The menu title (optional).
    ///   - items: The menu items.
    ///   - selectedIndex: The currently selected item index (default: 0).
    ///   - itemColor: The color for unselected items (default: nil).
    ///   - selectedColor: The color for the selected item (default: .cyan).
    ///   - selectionIndicator: The indicator shown before selected item (default: "▶ ").
    ///   - borderStyle: The border style (default: .rounded).
    ///   - borderColor: The border color (default: nil).
    public init(
        title: String? = nil,
        items: [MenuItem],
        selectedIndex: Int = 0,
        itemColor: Color? = nil,
        selectedColor: Color? = .cyan,
        selectionIndicator: String = "▶ ",
        borderStyle: BorderStyle? = .rounded,
        borderColor: Color? = nil
    ) {
        self.title = title
        self.items = items
        self.selectedIndex = max(0, min(selectedIndex, items.count - 1))
        self.itemColor = itemColor
        self.selectedColor = selectedColor
        self.selectionIndicator = selectionIndicator
        self.borderStyle = borderStyle
        self.borderColor = borderColor
    }

    public var body: Never {
        fatalError("Menu renders via Renderable")
    }
}

// MARK: - Menu Rendering

extension Menu: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        var lines: [String] = []

        // Title if present
        if let menuTitle = title {
            let titleStyled = ANSIRenderer.render(menuTitle, with: {
                var style = TextStyle()
                style.isBold = true
                style.foregroundColor = selectedColor ?? .cyan
                return style
            }())
            lines.append(" " + titleStyled)

            // Divider under title
            let dividerWidth = max(menuTitle.count + 2, maxItemWidth + 2)
            lines.append(" " + String(repeating: "─", count: dividerWidth))
        }

        // Menu items
        for (index, item) in items.enumerated() {
            let isSelected = index == selectedIndex
            let prefix = isSelected ? selectionIndicator : String(repeating: " ", count: selectionIndicator.count)

            // Build the label with optional shortcut
            let labelText: String
            if let shortcut = item.shortcut {
                labelText = "[\(shortcut)] \(item.label)"
            } else {
                labelText = "    \(item.label)"
            }

            let fullText = " " + prefix + labelText

            // Apply styling
            var style = TextStyle()
            if isSelected {
                style.isBold = true
                style.foregroundColor = selectedColor
            } else {
                style.foregroundColor = itemColor
            }

            let styledLine = ANSIRenderer.render(fullText, with: style)
            lines.append(styledLine)
        }

        // Create content buffer
        var contentBuffer = FrameBuffer(lines: lines)

        // Apply border if specified
        if let border = borderStyle {
            contentBuffer = applyBorder(to: contentBuffer, style: border, color: borderColor)
        }

        return contentBuffer
    }

    /// The maximum width of menu items (for sizing).
    private var maxItemWidth: Int {
        items.map { item -> Int in
            let shortcutPart = item.shortcut != nil ? 4 : 4  // "[x] " or "    "
            return selectionIndicator.count + shortcutPart + item.label.count
        }.max() ?? 0
    }

    /// Applies a border to the buffer.
    private func applyBorder(to buffer: FrameBuffer, style: BorderStyle, color: Color?) -> FrameBuffer {
        guard !buffer.isEmpty else { return buffer }

        let innerWidth = buffer.width
        var result: [String] = []

        // Top border
        let topLine = String(style.topLeft)
            + String(repeating: style.horizontal, count: innerWidth)
            + String(style.topRight)
        result.append(colorize(topLine, with: color))

        // Content lines with side borders
        for line in buffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            let borderedLine = String(style.vertical) + paddedLine + String(style.vertical)
            result.append(colorize(borderedLine, with: color, contentOnly: false))
        }

        // Bottom border
        let bottomLine = String(style.bottomLeft)
            + String(repeating: style.horizontal, count: innerWidth)
            + String(style.bottomRight)
        result.append(colorize(bottomLine, with: color))

        return FrameBuffer(lines: result)
    }

    /// Colorizes border characters only.
    private func colorize(_ string: String, with color: Color?, contentOnly: Bool = true) -> String {
        guard let color = color else { return string }
        var style = TextStyle()
        style.foregroundColor = color
        return ANSIRenderer.render(string, with: style)
    }
}

// MARK: - AnyView Helper

/// A type-erased view for conditional returns.
///
/// This is a temporary solution until we have proper `@ViewBuilder`
/// support for complex conditionals.
public struct AnyView: TView {
    private let _render: (RenderContext) -> FrameBuffer

    /// Creates an AnyView wrapping the given view.
    public init<V: TView>(_ view: V) {
        self._render = { context in
            SwiftTUI.renderToBuffer(view, context: context)
        }
    }

    public var body: Never {
        fatalError("AnyView renders via Renderable")
    }
}

extension AnyView: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        _render(context)
    }
}

extension TView {
    /// Wraps this view in an AnyView for type erasure.
    ///
    /// Use this when you need to return different view types from
    /// conditional branches.
    public func asAnyView() -> AnyView {
        AnyView(self)
    }
}
