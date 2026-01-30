//
//  Menu.swift
//  TUIkit
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
        let palette = context.environment.palette

        // Register key handlers if this is an interactive menu
        if let binding = selectionBinding {
            registerKeyHandlers(binding: binding, context: context)
        }

        var lines: [String] = []

        // Calculate the content width for full-width selection bar
        let contentWidth = maxItemWidth + 2  // +2 for padding

        // Track the divider line index (for T-junction rendering)
        var dividerLineIndex: Int?

        // Title if present
        if let menuTitle = title {
            let titleStyled = ANSIRenderer.render(
                menuTitle,
                with: {
                    var style = TextStyle()
                    style.isBold = true
                    style.foregroundColor = selectedColor ?? palette.accent
                    return style
                }()
            )
            lines.append(" " + titleStyled)

            // Mark divider position - actual divider will be rendered by applyBorder
            dividerLineIndex = lines.count
            lines.append("")  // Placeholder for divider
        }

        // Menu items
        let currentSelection = selectionBinding?.wrappedValue ?? selectedIndex

        for (index, item) in items.enumerated() {
            let isSelected = index == currentSelection

            // Build the label with optional shortcut
            let labelText: String
            if let shortcut = item.shortcut {
                labelText = "[\(shortcut)] \(item.label)"
            } else {
                labelText = "    \(item.label)"
            }

            // Build the full text with padding
            let fullText = " " + labelText

            // Pad to full width for selection bar
            let visibleLength = fullText.count
            let padding = max(0, contentWidth - visibleLength)
            let paddedText = fullText + String(repeating: " ", count: padding)

            // Apply styling
            var style = TextStyle()
            if isSelected {
                // Selected: bold text with dimmed background, highlighted foreground
                style.isBold = true
                style.foregroundColor = selectedColor ?? palette.accent
                // Use a dimmed version of the accent color for background
                style.backgroundColor = palette.selectionBackground
            } else {
                // Use palette foreground color if no custom itemColor is set
                style.foregroundColor = itemColor ?? palette.foreground
            }

            let styledLine = ANSIRenderer.render(paddedText, with: style)
            lines.append(styledLine)
        }

        // Create content buffer
        var contentBuffer = FrameBuffer(lines: lines)

        // Apply border - use explicit style, or fall back to appearance default
        let appearance = context.environment.appearance
        let effectiveBorderStyle = borderStyle ?? appearance.borderStyle
        let isBlockStyle = appearance.rawId == .block

        contentBuffer = applyBorder(
            to: contentBuffer,
            style: effectiveBorderStyle,
            color: borderColor,
            dividerLineIndex: dividerLineIndex,
            isBlockStyle: isBlockStyle,
            palette: palette
        )

        return contentBuffer
    }

    /// Registers key handlers for menu navigation.
    private func registerKeyHandlers(binding: Binding<Int>, context: RenderContext) {
        let itemCount = items.count
        let menuItems = items
        let selectCallback = onSelect

        context.tuiContext.keyEventDispatcher.addHandler { event in
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

            case .character(let character):
                // Check for shortcut
                for (index, item) in menuItems.enumerated() {
                    if let shortcut = item.shortcut,
                        shortcut.lowercased() == character.lowercased()
                    {
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
            let shortcutPart = 4  // "[x] " or "    " — always 4 characters wide
            return shortcutPart + item.label.count
        }.max() ?? 0
    }

    /// Applies a border to the buffer.
    ///
    /// - Parameters:
    ///   - buffer: The content buffer to wrap with border.
    ///   - style: The border style to use.
    ///   - color: The border color (optional).
    ///   - dividerLineIndex: If set, renders a horizontal divider with T-junctions at this line index.
    ///   - isBlockStyle: If true, uses half-block characters for smooth edges.
    private func applyBorder(
        to buffer: FrameBuffer,
        style: BorderStyle,
        color: Color?,
        dividerLineIndex: Int? = nil,
        isBlockStyle: Bool = false,
        palette: any Palette
    ) -> FrameBuffer {
        guard !buffer.isEmpty else { return buffer }

        let innerWidth = buffer.width
        var result: [String] = []

        if isBlockStyle {
            let headerFooterBg = palette.containerHeaderBackground
            let bodyBg = palette.containerBackground
            let hasHeader = dividerLineIndex != nil

            // Top border
            result.append(
                BorderRenderer.blockTopBorder(
                    innerWidth: innerWidth,
                    color: hasHeader ? headerFooterBg : bodyBg
                )
            )

            // Content lines with section-aware coloring
            for (index, line) in buffer.lines.enumerated() {
                let isHeaderLine = hasHeader && dividerLineIndex.map({ index < $0 }) ?? false
                let isDividerLine = hasHeader && dividerLineIndex.map({ index == $0 }) ?? false

                if isDividerLine {
                    result.append(
                        BorderRenderer.blockSeparator(
                            innerWidth: innerWidth,
                            foregroundColor: headerFooterBg,
                            backgroundColor: bodyBg
                        )
                    )
                } else if isHeaderLine {
                    result.append(
                        BorderRenderer.blockContentLine(
                            content: line,
                            innerWidth: innerWidth,
                            sectionColor: headerFooterBg
                        )
                    )
                } else {
                    result.append(
                        BorderRenderer.blockContentLine(
                            content: line,
                            innerWidth: innerWidth,
                            sectionColor: bodyBg
                        )
                    )
                }
            }

            // Bottom border
            result.append(BorderRenderer.blockBottomBorder(innerWidth: innerWidth, color: bodyBg))
        } else {
            let borderForeground = color ?? palette.border

            result.append(BorderRenderer.standardTopBorder(style: style, innerWidth: innerWidth, color: borderForeground))

            for (index, line) in buffer.lines.enumerated() {
                if let dividerIndex = dividerLineIndex, index == dividerIndex {
                    result.append(BorderRenderer.standardDivider(style: style, innerWidth: innerWidth, color: borderForeground))
                } else {
                    result.append(
                        BorderRenderer.standardContentLine(
                            content: line,
                            innerWidth: innerWidth,
                            style: style,
                            color: borderForeground
                        )
                    )
                }
            }

            result.append(BorderRenderer.standardBottomBorder(style: style, innerWidth: innerWidth, color: borderForeground))
        }

        return FrameBuffer(lines: result)
    }
}

// MARK: - AnyView Helper

