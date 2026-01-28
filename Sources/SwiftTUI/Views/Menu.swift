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

    public var body: some TView {
        let menuContent = VStack(alignment: .leading, spacing: 0) {
            // Title if present
            if let menuTitle = title {
                Text(menuTitle)
                    .bold()
                    .foregroundColor(selectedColor ?? .cyan)
                Divider()
                Spacer(minLength: 1)
            }

            // Menu items
            ForEach(items.indices, id: \.self) { index in
                menuItemView(for: index)
            }
        }
        .padding(EdgeInsets(horizontal: 1, vertical: 0))

        // Apply border if specified
        if let border = borderStyle {
            return menuContent.border(border, color: borderColor).asAnyView()
        } else {
            return menuContent.asAnyView()
        }
    }

    /// Creates the view for a single menu item.
    private func menuItemView(for index: Int) -> some TView {
        let item = items[index]
        let isSelected = index == selectedIndex
        let prefix = isSelected ? selectionIndicator : String(repeating: " ", count: selectionIndicator.count)

        // Build the label with optional shortcut
        let labelText: String
        if let shortcut = item.shortcut {
            labelText = "[\(shortcut)] \(item.label)"
        } else {
            labelText = "    \(item.label)"
        }

        let fullText = prefix + labelText

        if isSelected {
            if let color = selectedColor {
                return Text(fullText).bold().foregroundColor(color).asAnyView()
            } else {
                return Text(fullText).bold().asAnyView()
            }
        } else {
            if let color = itemColor {
                return Text(fullText).foregroundColor(color).asAnyView()
            } else {
                return Text(fullText).asAnyView()
            }
        }
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
