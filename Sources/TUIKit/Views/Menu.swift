//
//  Menu.swift
//  TUIKit
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
/// The currently selected item is highlighted.
///
/// # Basic Example (Static)
///
/// ```swift
/// Menu(
///     title: "Main Menu",
///     items: [
///         MenuItem(label: "Text Styles", shortcut: "1"),
///         MenuItem(label: "Colors", shortcut: "2"),
///         MenuItem(label: "Quit", shortcut: "q")
///     ],
///     selectedIndex: 0
/// )
/// ```
///
/// # Interactive Example (with Binding)
///
/// ```swift
/// struct ContentView: View {
///     @State var selection = 0
///
///     var body: some View {
///         Menu(
///             title: "Main Menu",
///             items: menuItems,
///             selection: $selection,
///             onSelect: { index in
///                 handleSelection(index)
///             }
///         )
///     }
/// }
/// ```
public struct Menu: View {
    /// The menu title (optional).
    public let title: String?

    /// The menu items.
    public let items: [MenuItem]

    /// The currently selected item index.
    public var selectedIndex: Int

    /// Binding to the selection (for interactive menus).
    private let selectionBinding: Binding<Int>?

    /// Callback when an item is selected (Enter or shortcut).
    private let onSelect: ((Int) -> Void)?

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

    /// Creates a static menu (non-interactive).
    ///
    /// - Parameters:
    ///   - title: The menu title (optional).
    ///   - items: The menu items.
    ///   - selectedIndex: The currently selected item index (default: 0).
    ///   - itemColor: The color for unselected items (default: theme foreground).
    ///   - selectedColor: The color for the selected item (default: theme accent).
    ///   - selectionIndicator: The indicator shown before selected item (default: "▶ ").
    ///   - borderStyle: The border style (default: appearance borderStyle, nil for no border).
    ///   - borderColor: The border color (default: theme border).
    public init(
        title: String? = nil,
        items: [MenuItem],
        selectedIndex: Int = 0,
        itemColor: Color? = nil,
        selectedColor: Color? = nil,
        selectionIndicator: String = "▶ ",
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil
    ) {
        self.title = title
        self.items = items
        self.selectedIndex = max(0, min(selectedIndex, items.count - 1))
        self.selectionBinding = nil
        self.onSelect = nil
        self.itemColor = itemColor
        self.selectedColor = selectedColor
        self.selectionIndicator = selectionIndicator
        self.borderStyle = borderStyle
        self.borderColor = borderColor
    }

    /// Creates an interactive menu with selection binding.
    ///
    /// - Parameters:
    ///   - title: The menu title (optional).
    ///   - items: The menu items.
    ///   - selection: Binding to the selected index.
    ///   - onSelect: Callback when item is activated (Enter or shortcut).
    ///   - itemColor: The color for unselected items (default: theme foreground).
    ///   - selectedColor: The color for the selected item (default: theme accent).
    ///   - selectionIndicator: The indicator shown before selected item (default: "▶ ").
    ///   - borderStyle: The border style (default: appearance borderStyle, nil for no border).
    ///   - borderColor: The border color (default: theme border).
    public init(
        title: String? = nil,
        items: [MenuItem],
        selection: Binding<Int>,
        onSelect: ((Int) -> Void)? = nil,
        itemColor: Color? = nil,
        selectedColor: Color? = nil,
        selectionIndicator: String = "▶ ",
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil
    ) {
        self.title = title
        self.items = items
        self.selectedIndex = max(0, min(selection.wrappedValue, items.count - 1))
        self.selectionBinding = selection
        self.onSelect = onSelect
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
        // Register key handlers if this is an interactive menu
        if let binding = selectionBinding {
            registerKeyHandlers(binding: binding)
        }

        var lines: [String] = []

        // Title if present
        if let menuTitle = title {
            let titleStyled = ANSIRenderer.render(menuTitle, with: {
                var style = TextStyle()
                style.isBold = true
                style.foregroundColor = selectedColor ?? Color.theme.accent
                return style
            }())
            lines.append(" " + titleStyled)

            // Divider under title (same color as border)
            let dividerWidth = max(menuTitle.count, maxItemWidth + 1)
            let dividerLine = String(repeating: "─", count: dividerWidth)
            let dividerStyled = colorizeBorder(dividerLine, with: borderColor)
            lines.append(dividerStyled)
        }

        // Menu items
        let currentSelection = selectionBinding?.wrappedValue ?? selectedIndex
        let appearance = context.environment.appearance
        let isBlockAppearance = appearance.id == .block
        
        for (index, item) in items.enumerated() {
            let isSelected = index == currentSelection
            
            // Build the label with optional shortcut
            let labelText: String
            if let shortcut = item.shortcut {
                labelText = "[\(shortcut)] \(item.label)"
            } else {
                labelText = "    \(item.label)"
            }

            // For block appearance: no indicator, use background highlight
            // For other appearances: use indicator prefix
            let fullText: String
            if isBlockAppearance {
                fullText = " " + labelText
            } else {
                let prefix = isSelected ? selectionIndicator : String(repeating: " ", count: selectionIndicator.count)
                fullText = " " + prefix + labelText
            }

            // Apply styling
            var style = TextStyle()
            if isSelected {
                style.isBold = true
                if isBlockAppearance {
                    // Block appearance: use background highlight
                    style.foregroundColor = Color.theme.background
                    style.backgroundColor = selectedColor ?? Color.theme.accent
                } else {
                    // Other appearances: just change foreground color
                    style.foregroundColor = selectedColor ?? Color.theme.accent
                }
            } else {
                // Use theme foreground color if no custom itemColor is set
                style.foregroundColor = itemColor ?? Color.theme.foreground
            }

            let styledLine = ANSIRenderer.render(fullText, with: style)
            lines.append(styledLine)
        }

        // Create content buffer
        var contentBuffer = FrameBuffer(lines: lines)

        // Apply border - use explicit style, or fall back to appearance default
        let effectiveBorderStyle = borderStyle ?? context.environment.appearance.borderStyle
        contentBuffer = applyBorder(to: contentBuffer, style: effectiveBorderStyle, color: borderColor)

        return contentBuffer
    }

    /// Registers key handlers for menu navigation.
    private func registerKeyHandlers(binding: Binding<Int>) {
        let itemCount = items.count
        let menuItems = items
        let selectCallback = onSelect

        KeyEventDispatcher.shared.addHandler { event in
            switch event.key {
            case .up:
                // Move selection up
                let current = binding.wrappedValue
                if current > 0 {
                    binding.wrappedValue = current - 1
                } else {
                    binding.wrappedValue = itemCount - 1  // Wrap to bottom
                }
                return true

            case .down:
                // Move selection down
                let current = binding.wrappedValue
                if current < itemCount - 1 {
                    binding.wrappedValue = current + 1
                } else {
                    binding.wrappedValue = 0  // Wrap to top
                }
                return true

            case .enter:
                // Select current item
                selectCallback?(binding.wrappedValue)
                return true

            case .character(let char):
                // Check for shortcut
                for (index, item) in menuItems.enumerated() {
                    if let shortcut = item.shortcut,
                       shortcut.lowercased() == char.lowercased() {
                        binding.wrappedValue = index
                        selectCallback?(index)
                        return true
                    }
                }
                return false

            default:
                return false
            }
        }
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

        // Border character (optionally colored)
        let vertical = colorizeBorder(String(style.vertical), with: color)

        // Top border
        let topLine = String(style.topLeft)
            + String(repeating: style.horizontal, count: innerWidth)
            + String(style.topRight)
        result.append(colorizeBorder(topLine, with: color))

        // Content lines with side borders
        // Important: Reset ANSI before right border to prevent color bleeding
        let reset = "\u{1B}[0m"
        for line in buffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            // Left border + content + reset + right border
            let borderedLine = vertical + paddedLine + reset + vertical
            result.append(borderedLine)
        }

        // Bottom border
        let bottomLine = String(style.bottomLeft)
            + String(repeating: style.horizontal, count: innerWidth)
            + String(style.bottomRight)
        result.append(colorizeBorder(bottomLine, with: color))

        return FrameBuffer(lines: result)
    }

    /// Colorizes border characters.
    private func colorizeBorder(_ string: String, with color: Color?) -> String {
        var style = TextStyle()
        style.foregroundColor = color ?? Color.theme.border
        return ANSIRenderer.render(string, with: style)
    }
}

// MARK: - AnyView Helper

/// A type-erased view for conditional returns.
///
/// This is a temporary solution until we have proper `@ViewBuilder`
/// support for complex conditionals.
public struct AnyView: View {
    private let _render: (RenderContext) -> FrameBuffer

    /// Creates an AnyView wrapping the given view.
    public init<V: View>(_ view: V) {
        self._render = { context in
            TUIKit.renderToBuffer(view, context: context)
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

extension View {
    /// Wraps this view in an AnyView for type erasure.
    ///
    /// Use this when you need to return different view types from
    /// conditional branches.
    public func asAnyView() -> AnyView {
        AnyView(self)
    }
}
