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
        
        // Calculate the content width for full-width selection bar
        let contentWidth = maxItemWidth + 2  // +2 for padding
        
        // Track the divider line index (for T-junction rendering)
        var dividerLineIndex: Int? = nil

        // Title if present
        if let menuTitle = title {
            let titleStyled = ANSIRenderer.render(menuTitle, with: {
                var style = TextStyle()
                style.isBold = true
                style.foregroundColor = selectedColor ?? Color.theme.accent
                return style
            }())
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
                style.foregroundColor = selectedColor ?? Color.theme.accent
                // Use a dimmed version of the accent color for background
                style.backgroundColor = Color.theme.selectionBackground
            } else {
                // Use theme foreground color if no custom itemColor is set
                style.foregroundColor = itemColor ?? Color.theme.foreground
            }

            let styledLine = ANSIRenderer.render(paddedText, with: style)
            lines.append(styledLine)
        }

        // Create content buffer
        var contentBuffer = FrameBuffer(lines: lines)

        // Apply border - use explicit style, or fall back to appearance default
        let appearance = context.environment.appearance
        let effectiveBorderStyle = borderStyle ?? appearance.borderStyle
        let isBlockStyle = appearance.id == .block
        
        contentBuffer = applyBorder(
            to: contentBuffer,
            style: effectiveBorderStyle,
            color: borderColor,
            dividerLineIndex: dividerLineIndex,
            isBlockStyle: isBlockStyle
        )

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

            case .character(let character):
                // Check for shortcut
                for (index, item) in menuItems.enumerated() {
                    if let shortcut = item.shortcut,
                       shortcut.lowercased() == character.lowercased() {
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
        isBlockStyle: Bool = false
    ) -> FrameBuffer {
        guard !buffer.isEmpty else { return buffer }

        let innerWidth = buffer.width
        var result: [String] = []
        
        if isBlockStyle {
            // Block style: use half-blocks with special coloring
            // Header/Footer BG = darker (containerHeaderBackground)
            // Body BG = lighter (containerBackground)
            // App BG = transparent (no background set)
            let headerFooterBg = Color.theme.containerHeaderBackground
            let bodyBg = Color.theme.containerBackground
            
            // Determine if we have a header (divider present)
            let hasHeader = dividerLineIndex != nil
            
            // Top border: ▄▄▄
            // FG = header background, BG = App background (transparent/none)
            let topLine = String(repeating: "▄", count: innerWidth + 2)
            if hasHeader {
                result.append(colorizeWithForeground(topLine, foreground: headerFooterBg))
            } else {
                // No header: use body background for top
                result.append(colorizeWithForeground(topLine, foreground: bodyBg))
            }
            
            // Content lines with side borders
            for (index, line) in buffer.lines.enumerated() {
                let isHeaderLine = hasHeader && dividerLineIndex.map({ index < $0 }) ?? false
                let isDividerLine = hasHeader && dividerLineIndex.map({ index == $0 }) ?? false
                
                if isDividerLine {
                    // Header/Body separator: ▀▀▀
                    // FG = header BG, BG = body BG (creates smooth transition)
                    let dividerLine = String(repeating: "▀", count: innerWidth + 2)
                    result.append(colorizeWithBoth(dividerLine, foreground: headerFooterBg, background: bodyBg))
                } else if isHeaderLine {
                    // Header line: █ borders and content with header background
                    let paddedLine = line.padToVisibleWidth(innerWidth)
                    let sideBorder = colorizeWithForeground("█", foreground: headerFooterBg)
                    let styledContent = applyBackground(paddedLine, background: headerFooterBg)
                    result.append(sideBorder + styledContent + ANSIRenderer.reset + sideBorder)
                } else {
                    // Body line: █ borders with body background
                    let paddedLine = line.padToVisibleWidth(innerWidth)
                    let sideBorder = colorizeWithForeground("█", foreground: bodyBg)
                    let styledContent = applyBackground(paddedLine, background: bodyBg)
                    result.append(sideBorder + styledContent + ANSIRenderer.reset + sideBorder)
                }
            }
            
            // Bottom border: ▀▀▀
            // FG = body background, BG = App background (transparent)
            let bottomLine = String(repeating: "▀", count: innerWidth + 2)
            result.append(colorizeWithForeground(bottomLine, foreground: bodyBg))
        } else {
            // Standard style: regular box-drawing characters
            let vertical = colorizeBorder(String(style.vertical), with: color)

            // Top border
            let topLine = String(style.topLeft)
                + String(repeating: style.horizontal, count: innerWidth)
                + String(style.topRight)
            result.append(colorizeBorder(topLine, with: color))

            // Content lines with side borders
            for (index, line) in buffer.lines.enumerated() {
                if let dividerIndex = dividerLineIndex, index == dividerIndex {
                    // Render horizontal divider with T-junctions
                    let dividerLine = String(style.leftT)
                        + String(repeating: style.horizontal, count: innerWidth)
                        + String(style.rightT)
                    result.append(colorizeBorder(dividerLine, with: color))
                } else {
                    let paddedLine = line.padToVisibleWidth(innerWidth)
                    result.append(vertical + paddedLine + ANSIRenderer.reset + vertical)
                }
            }

            // Bottom border
            let bottomLine = String(style.bottomLeft)
                + String(repeating: style.horizontal, count: innerWidth)
                + String(style.bottomRight)
            result.append(colorizeBorder(bottomLine, with: color))
        }

        return FrameBuffer(lines: result)
    }
    
    /// Colorizes with only foreground color (for separator transitions).
    private func colorizeWithForeground(_ string: String, foreground: Color) -> String {
        var style = TextStyle()
        style.foregroundColor = foreground
        return ANSIRenderer.render(string, with: style)
    }
    
    /// Colorizes with both foreground and background.
    private func colorizeWithBoth(_ string: String, foreground: Color, background: Color) -> String {
        var style = TextStyle()
        style.foregroundColor = foreground
        style.backgroundColor = background
        return ANSIRenderer.render(string, with: style)
    }
    
    /// Applies a background color to content, re-applying after any resets.
    private func applyBackground(_ string: String, background: Color) -> String {
        // ANSIRenderer.backgroundCode already returns a complete ANSI sequence
        let bgCode = ANSIRenderer.backgroundCode(for: background)
        // Replace any reset codes with reset + background to maintain the background
        let stringWithPersistentBg = string.replacingOccurrences(of: ANSIRenderer.reset, with: ANSIRenderer.reset + bgCode)
        return bgCode + stringWithPersistentBg
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
