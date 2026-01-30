//
//  StatusBar.swift
//  TUIKit
//
//  A status bar that displays keyboard shortcuts and context-sensitive actions.
//  Always rendered at the bottom of the terminal, never dimmed by overlays.
//

import Foundation

// MARK: - Status Bar Style

/// The visual style of the status bar.
public enum StatusBarStyle: Sendable {
    /// A single line with horizontal padding.
    case compact

    /// Block-style border (like `BorderStyle.block`).
    case bordered
}

// MARK: - Status Bar Alignment

/// The horizontal alignment of items within the status bar.
public enum StatusBarAlignment: Sendable {
    /// Items are aligned to the left (leading edge).
    case leading

    /// Items are aligned to the right (trailing edge).
    case trailing

    /// Items are centered horizontally.
    case center

    /// Items are evenly distributed across the full width.
    case justified
}

// MARK: - Shortcut Symbols

/// A collection of Unicode symbols commonly used for keyboard shortcuts.
///
/// Use these constants instead of typing Unicode characters directly.
/// They provide a consistent look and are easier to read in code.
///
/// # Example
///
/// ```swift
/// StatusBarItem(shortcut: .escape, label: "close") { dismiss() }
/// StatusBarItem(shortcut: .arrowsUpDown, label: "nav")
/// StatusBarItem(shortcut: .enter, label: "select", key: .enter)
/// ```
public enum Shortcut {
    // MARK: - Special Keys

    /// Escape key symbol: ⎋
    public static let escape = "⎋"

    /// Return/Enter key symbol: ↵
    public static let enter = "↵"

    /// Alternative return symbol: ⏎
    public static let returnKey = "⏎"

    /// Tab key symbol: ⇥
    public static let tab = "⇥"

    /// Shift+Tab (backtab) symbol: ⇤
    public static let shiftTab = "⇤"

    /// Backspace/Delete symbol: ⌫
    public static let backspace = "⌫"

    /// Forward delete symbol: ⌦
    public static let delete = "⌦"

    /// Space bar symbol: ␣
    public static let space = "␣"

    // MARK: - Arrow Keys (Single)

    /// Up arrow: ↑
    public static let arrowUp = "↑"

    /// Down arrow: ↓
    public static let arrowDown = "↓"

    /// Left arrow: ←
    public static let arrowLeft = "←"

    /// Right arrow: →
    public static let arrowRight = "→"

    // MARK: - Arrow Key Combinations

    /// Up and down arrows: ↑↓
    public static let arrowsUpDown = "↑↓"

    /// Left and right arrows: ←→
    public static let arrowsLeftRight = "←→"

    /// All four arrows: ↑↓←→
    public static let arrowsAll = "↑↓←→"

    /// Vertical arrows (alternative): ⇅
    public static let arrowsVertical = "⇅"

    /// Horizontal arrows (alternative): ⇆
    public static let arrowsHorizontal = "⇆"

    // MARK: - Modifier Keys

    /// Command key (Mac): ⌘
    public static let command = "⌘"

    /// Option/Alt key (Mac): ⌥
    public static let option = "⌥"

    /// Control key: ⌃
    public static let control = "⌃"

    /// Shift key: ⇧
    public static let shift = "⇧"

    /// Caps Lock: ⇪
    public static let capsLock = "⇪"

    // MARK: - Function Keys

    /// Function key prefix: Fn
    public static let fn = "Fn"

    // MARK: - Navigation

    /// Home key symbol: ⤒
    public static let home = "⤒"

    /// End key symbol: ⤓
    public static let end = "⤓"

    /// Page Up symbol: ⇞
    public static let pageUp = "⇞"

    /// Page Down symbol: ⇟
    public static let pageDown = "⇟"

    // MARK: - Actions

    /// Plus/Add symbol: +
    public static let plus = "+"

    /// Minus/Remove symbol: −
    public static let minus = "−"

    /// Checkmark/Confirm: ✓
    public static let checkmark = "✓"

    /// Cross/Cancel: ✗
    public static let cross = "✗"

    /// Search/Find: 🔍 (or use "?" for simpler display)
    public static let search = "?"

    /// Help symbol: ?
    public static let help = "?"

    /// Save symbol: 💾 (or use "S" for simpler display)
    public static let save = "S"

    // MARK: - Common Shortcuts

    /// Quit shortcut: q
    public static let quit = "q"

    /// Yes shortcut: y
    public static let yes = "y"

    /// No shortcut: n
    public static let no = "n"

    /// Cancel shortcut: c
    public static let cancel = "c"

    /// OK shortcut: o
    public static let ok = "o"

    // MARK: - Brackets and Selection

    /// Selection indicator: ▸
    public static let selectionRight = "▸"

    /// Selection indicator left: ◂
    public static let selectionLeft = "◂"

    /// Bullet point: •
    public static let bullet = "•"

    /// Square selection: ▪
    public static let squareBullet = "▪"

    // MARK: - Combining Helpers

    /// Combines multiple shortcuts with a separator.
    ///
    /// - Parameters:
    ///   - shortcuts: The shortcuts to combine.
    ///   - separator: The separator (default: empty string).
    /// - Returns: The combined shortcut string.
    ///
    /// # Example
    ///
    /// ```swift
    /// Shortcut.combine(.control, "c") // "⌃c"
    /// Shortcut.combine(.shift, .tab)   // "⇧⇥"
    /// ```
    public static func combine(_ shortcuts: String..., separator: String = "") -> String {
        shortcuts.joined(separator: separator)
    }

    /// Creates a Ctrl+key shortcut display.
    ///
    /// - Parameter key: The key character.
    /// - Returns: The formatted shortcut (e.g., "^c").
    public static func ctrl(_ key: Character) -> String {
        "^\(key)"
    }

    /// Creates a range shortcut display (e.g., "1-9").
    ///
    /// - Parameters:
    ///   - start: The start of the range.
    ///   - end: The end of the range.
    /// - Returns: The formatted range (e.g., "1-9").
    public static func range(_ start: String, _ end: String) -> String {
        "\(start)-\(end)"
    }
}

// MARK: - Status Bar Item Order

/// Defines the display order of status bar items.
///
/// Items are sorted by their order value (ascending). Lower values appear first (left).
/// System items appear on the right side with high order values.
///
/// # Order Ranges
///
/// - `0-99`: Reserved for leading items
/// - `100-899`: User-defined items (default: 500)
/// - `900-999`: Reserved for system items (quit, help, theme) on the right
///
/// # System Item Layout (from right edge)
///
/// ```
/// [user items...] [q quit] [? help] [t theme]
/// ```
///
/// # Example
///
/// ```swift
/// // Custom item appears on the left (before system items)
/// StatusBarItem(shortcut: "s", label: "save", order: .default)
/// ```
public struct StatusBarItemOrder: Comparable, Sendable {
    /// The numeric sort value (lower values appear first).
    public let value: Int

    /// Creates a status bar item order with the given sort value.
    ///
    /// - Parameter value: The numeric sort value.
    public init(_ value: Int) {
        self.value = value
    }

    /// Compares two orders by their numeric value.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }

    // MARK: - User Item Orders

    /// Default order for user-defined items (appears on the left).
    public static let `default` = Self(500)

    /// Order for items that should appear early (leftmost user items).
    public static let early = Self(100)

    /// Order for items that should appear late (rightmost user items, before system items).
    public static let late = Self(800)

    // MARK: - System Item Orders (right side)

    /// Order for the quit item (leftmost of system items).
    /// Appears as: `[...user items] [q quit] [a appearance] [t theme]`
    public static let quit = Self(900)

    /// Order for the appearance item (middle system item).
    public static let appearance = Self(910)

    /// Order for the theme item (rightmost).
    public static let theme = Self(920)
}

// MARK: - Status Bar Item Protocol

/// A protocol for items that can be displayed in a status bar.
///
/// Implement this protocol to create custom status bar items.
/// The default `StatusBarItem` already conforms to this protocol.
public protocol StatusBarItemProtocol: Sendable {
    /// The unique identifier for this item.
    var id: String { get }

    /// The shortcut key(s) to display (e.g., "q", "↑↓", "⎋").
    var shortcut: String { get }

    /// A short description (one word, e.g., "quit", "nav", "close").
    var label: String { get }

    /// The key event that triggers this item's action.
    ///
    /// Return nil if the item is purely informational (no action).
    var triggerKey: Key? { get }

    /// The display order of this item.
    ///
    /// Items are sorted by order (ascending). Lower values appear first.
    var order: StatusBarItemOrder { get }

    /// Whether this item matches a given key event.
    ///
    /// Override this for complex matching (e.g., arrow keys).
    func matches(_ event: KeyEvent) -> Bool
}

// Default implementations
extension StatusBarItemProtocol {
    /// Default order for user-defined items.
    public var order: StatusBarItemOrder { .default }

    /// Whether this item's trigger key matches the given key event.
    ///
    /// Returns `false` if the item has no trigger key (informational only).
    ///
    /// - Parameter event: The key event to match against.
    /// - Returns: `true` if the event matches this item's trigger key.
    public func matches(_ event: KeyEvent) -> Bool {
        guard let trigger = triggerKey else { return false }
        return event.key == trigger
    }
}

// MARK: - Status Bar Item

/// A status bar item displaying a shortcut and its description.
///
/// # Example
///
/// ```swift
/// StatusBarItem(shortcut: "q", label: "quit") {
///     app.quit()
/// }
///
/// StatusBarItem(shortcut: "↑↓", label: "nav", key: .up) // Info only, no action
///
/// // With custom order
/// StatusBarItem(shortcut: "s", label: "save", order: .early) {
///     save()
/// }
/// ```
public struct StatusBarItem: StatusBarItemProtocol, Identifiable {
    /// The unique identifier for this item.
    public let id: String

    /// The shortcut key(s) displayed to the user (e.g. `"q"`, `"↑↓"`).
    public let shortcut: String

    /// The descriptive label shown next to the shortcut (e.g. `"quit"`, `"nav"`).
    public let label: String

    /// The key that triggers this item's action, or `nil` for informational items.
    public let triggerKey: Key?

    /// The sort order controlling horizontal position in the status bar.
    public let order: StatusBarItemOrder

    /// The action to perform when the shortcut is triggered.
    private let action: (@Sendable () -> Void)?

    /// Creates a status bar item with an action.
    ///
    /// - Parameters:
    ///   - shortcut: The shortcut key(s) to display.
    ///   - label: A short description (one word).
    ///   - key: The key that triggers the action (derived from shortcut if not provided).
    ///   - order: The display order (default: `.default`).
    ///   - action: The action to perform.
    public init(
        shortcut: String,
        label: String,
        key: Key? = nil,
        order: StatusBarItemOrder = .default,
        action: (@Sendable () -> Void)? = nil
    ) {
        self.id = "\(shortcut)-\(label)"
        self.shortcut = shortcut
        self.label = label
        self.order = order
        self.action = action

        // Derive trigger key from shortcut if not explicitly provided
        if let explicitKey = key {
            self.triggerKey = explicitKey
        } else if let mappedKey = Self.keyFromShortcut(shortcut) {
            // First try to map special symbols to keys
            self.triggerKey = mappedKey
        } else if shortcut.count == 1, let char = shortcut.first {
            // Single character becomes a character key
            self.triggerKey = .character(char)
        } else {
            self.triggerKey = nil
        }
    }

    /// Creates an informational status bar item (no action).
    ///
    /// - Parameters:
    ///   - shortcut: The shortcut key(s) to display.
    ///   - label: A short description.
    ///   - order: The display order (default: `.default`).
    public init(shortcut: String, label: String, order: StatusBarItemOrder = .default) {
        self.init(shortcut: shortcut, label: label, key: nil, order: order, action: nil)
    }

    /// Whether this item has an action to execute.
    public var hasAction: Bool {
        action != nil
    }

    /// Executes the item's action.
    public func execute() {
        action?()
    }

    /// Maps common shortcut symbols to Key values.
    private static func keyFromShortcut(_ shortcut: String) -> Key? {
        switch shortcut.lowercased() {
        case "⎋", "esc", "escape":
            return .escape
        case "↵", "⏎", "enter", "return":
            return .enter
        case "⇥", "tab":
            return .tab
        case "⌫", "backspace", "del":
            return .backspace
        case "↑":
            return .up
        case "↓":
            return .down
        case "←":
            return .left
        case "→":
            return .right
        default:
            return nil
        }
    }

    /// Override matching for special cases.
    public func matches(_ event: KeyEvent) -> Bool {
        // Handle arrow key combinations like "↑↓"
        if shortcut.contains("↑") && event.key == .up { return true }
        if shortcut.contains("↓") && event.key == .down { return true }
        if shortcut.contains("←") && event.key == .left { return true }
        if shortcut.contains("→") && event.key == .right { return true }

        // Standard matching
        guard let trigger = triggerKey else { return false }

        // For character keys, do case-sensitive matching
        // "n" only matches 'n', "N" only matches 'N' (Shift+n)
        if case .character(let triggerChar) = trigger,
            case .character(let eventChar) = event.key
        {
            return triggerChar == eventChar
        }

        return event.key == trigger
    }
}

// MARK: - System Status Bar Items

/// System status bar items that are always present.
///
/// These items are automatically added to the status bar by the framework.
/// They appear in a fixed order and provide essential app-wide functionality.
///
/// System items include:
/// - **quit** (`q`): Exits the application
/// - **appearance** (`a`): Cycles through appearances
/// - **theme** (`t`): Cycles through themes
public enum SystemStatusBarItem {
    /// The quit item (`q quit`).
    ///
    /// This item is always present and exits the application.
    public static let quit = StatusBarItem(
        shortcut: "q",
        label: "quit",
        order: .quit
    )

    /// The appearance item (`a appearance`).
    ///
    /// Cycles through available appearances (border styles).
    /// Action must be set by the framework.
    public static let appearance = StatusBarItem(
        shortcut: "a",
        label: "appearance",
        order: .appearance
    )

    /// The theme item (`t theme`).
    ///
    /// Cycles through available themes. Action must be set by the framework.
    public static let theme = StatusBarItem(
        shortcut: "t",
        label: "theme",
        order: .theme
    )

    /// All system items in their default order.
    public static var all: [StatusBarItem] {
        [quit, appearance, theme]
    }

    /// Creates system items with custom actions.
    ///
    /// - Parameters:
    ///   - onQuit: Action for quit (default: exits app).
    ///   - onAppearance: Action for appearance cycling (optional).
    ///   - onTheme: Action for theme cycling (optional).
    /// - Returns: Array of configured system items.
    public static func items(
        onQuit: (@Sendable () -> Void)? = nil,
        onAppearance: (@Sendable () -> Void)? = nil,
        onTheme: (@Sendable () -> Void)? = nil
    ) -> [StatusBarItem] {
        var result: [StatusBarItem] = []

        // Quit is always present
        result.append(
            StatusBarItem(
                shortcut: "q",
                label: "quit",
                order: .quit,
                action: onQuit
            )
        )

        // Appearance is present if action is provided
        if let onAppearance {
            result.append(
                StatusBarItem(
                    shortcut: "a",
                    label: "appearance",
                    order: .appearance,
                    action: onAppearance
                )
            )
        }

        // Theme is present if action is provided
        if let onTheme {
            result.append(
                StatusBarItem(
                    shortcut: "t",
                    label: "theme",
                    order: .theme,
                    action: onTheme
                )
            )
        }

        return result
    }
}

// MARK: - Status Bar Item Builder

/// Result builder for creating status bar items.
@resultBuilder
public struct StatusBarItemBuilder {
    /// Combines multiple item arrays into a single flat array.
    public static func buildBlock(_ components: [any StatusBarItemProtocol]...) -> [any StatusBarItemProtocol] {
        components.flatMap { $0 }
    }

    /// Combines an array of item arrays (from `for` loops).
    public static func buildArray(_ components: [[any StatusBarItemProtocol]]) -> [any StatusBarItemProtocol] {
        components.flatMap { $0 }
    }

    /// Handles optional item arrays (from `if` without `else`).
    public static func buildOptional(_ component: [any StatusBarItemProtocol]?) -> [any StatusBarItemProtocol] {
        component ?? []
    }

    /// Handles the first branch of an `if`/`else`.
    public static func buildEither(first component: [any StatusBarItemProtocol]) -> [any StatusBarItemProtocol] {
        component
    }

    /// Handles the second branch of an `if`/`else`.
    public static func buildEither(second component: [any StatusBarItemProtocol]) -> [any StatusBarItemProtocol] {
        component
    }

    /// Wraps a single item into an array.
    public static func buildExpression(_ expression: any StatusBarItemProtocol) -> [any StatusBarItemProtocol] {
        [expression]
    }
}

// MARK: - StatusBar View

/// A status bar that displays at the bottom of the terminal.
///
/// The status bar shows keyboard shortcuts and their descriptions.
/// It's rendered separately from the main view tree and is never
/// affected by overlays or dimming.
///
/// # Layout
///
/// The status bar consists of two containers:
/// - **User Container** (left): User-defined items, sorted by order
/// - **System Container** (right): System items (quit, help, theme), fixed order
///
/// ```
/// ┌────────────────────────────────────────┬───────────────────────────────┐
/// │ s save   x action   ↑↓ nav             │ q quit   ? help   t theme    │
/// └────────────────────────────────────────┴───────────────────────────────┘
/// ```
///
/// # Usage
///
/// To set status bar items, use the environment:
///
/// ```swift
/// struct MyView: View {
///     @Environment(\.statusBar) var statusBar
///
///     var body: some View {
///         VStack {
///             Text("Hello")
///         }
///         .onAppear {
///             statusBar.setItems([
///                 StatusBarItem(shortcut: "s", label: "save"),
///                 StatusBarItem(shortcut: "↑↓", label: "nav"),
///             ])
///         }
///     }
/// }
/// ```
public struct StatusBar: View {
    /// User items (left container).
    public let userItems: [any StatusBarItemProtocol]

    /// System items (right container).
    public let systemItems: [any StatusBarItemProtocol]

    /// The visual style.
    public let style: StatusBarStyle

    /// The horizontal alignment of user items within the left container.
    public let alignment: StatusBarAlignment

    /// The highlight color for shortcut keys.
    public let highlightColor: Color

    /// The label color.
    public let labelColor: Color?

    /// Creates a status bar with separate user and system items.
    ///
    /// - Parameters:
    ///   - userItems: User-defined items (left container).
    ///   - systemItems: System items (right container).
    ///   - style: The visual style (default: `.compact`).
    ///   - alignment: The alignment of user items (default: `.leading`).
    ///   - highlightColor: The color for shortcut keys (default: `.cyan`).
    ///   - labelColor: The color for labels (default: nil, terminal default).
    public init(
        userItems: [any StatusBarItemProtocol] = [],
        systemItems: [any StatusBarItemProtocol] = [],
        style: StatusBarStyle = .compact,
        alignment: StatusBarAlignment = .leading,
        highlightColor: Color = .cyan,
        labelColor: Color? = nil
    ) {
        self.userItems = userItems
        self.systemItems = systemItems
        self.style = style
        self.alignment = alignment
        self.highlightColor = highlightColor
        self.labelColor = labelColor
    }

    /// Creates a status bar with all items combined (legacy compatibility).
    ///
    /// - Parameters:
    ///   - items: All items to display (will be treated as user items).
    ///   - style: The visual style (default: `.compact`).
    ///   - alignment: The horizontal alignment (default: `.justified`).
    ///   - highlightColor: The color for shortcut keys (default: `.cyan`).
    ///   - labelColor: The color for labels (default: nil, terminal default).
    public init(
        items: [any StatusBarItemProtocol],
        style: StatusBarStyle = .compact,
        alignment: StatusBarAlignment = .justified,
        highlightColor: Color = .cyan,
        labelColor: Color? = nil
    ) {
        self.userItems = items
        self.systemItems = []
        self.style = style
        self.alignment = alignment
        self.highlightColor = highlightColor
        self.labelColor = labelColor
    }

    /// Creates a status bar using a builder.
    ///
    /// - Parameters:
    ///   - style: The visual style.
    ///   - alignment: The horizontal alignment.
    ///   - highlightColor: The color for shortcut keys.
    ///   - labelColor: The color for labels.
    ///   - builder: A closure that returns items.
    public init(
        style: StatusBarStyle = .compact,
        alignment: StatusBarAlignment = .justified,
        highlightColor: Color = .cyan,
        labelColor: Color? = nil,
        @StatusBarItemBuilder _ builder: () -> [any StatusBarItemProtocol]
    ) {
        self.userItems = builder()
        self.systemItems = []
        self.style = style
        self.alignment = alignment
        self.highlightColor = highlightColor
        self.labelColor = labelColor
    }

    /// All items combined (sorted user items, then filtered system items).
    ///
    /// User items are sorted by their `order` property.
    /// System items maintain their fixed order (quit, help, theme).
    /// User items override system items with the same shortcut.
    /// Use this for event handling to check all items.
    public var allItems: [any StatusBarItemProtocol] {
        let userShortcuts = Set(userItems.map { $0.shortcut })
        let filteredSystemItems = systemItems.filter { !userShortcuts.contains($0.shortcut) }
        return userItems.sorted { $0.order < $1.order } + filteredSystemItems
    }

    /// Whether the status bar has any items to display.
    public var hasItems: Bool {
        !userItems.isEmpty || !systemItems.isEmpty
    }

    public var body: Never {
        fatalError("StatusBar renders via Renderable")
    }
}

// MARK: - StatusBar Rendering

extension StatusBar: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Get shortcuts used by user items (for deduplication)
        let userShortcuts = Set(userItems.map { $0.shortcut })

        // Filter out system items that are overridden by user items
        let filteredSystemItems = systemItems.filter { !userShortcuts.contains($0.shortcut) }

        // Combine: sorted user items + filtered system items (fixed order)
        let sortedUserItems = userItems.sorted { $0.order < $1.order }
        let combinedItems = sortedUserItems + filteredSystemItems

        guard !combinedItems.isEmpty else {
            return FrameBuffer()
        }

        // Build item strings
        let itemStrings = combinedItems.map { item -> String in
            let shortcutStyled = ANSIRenderer.render(
                item.shortcut,
                with: {
                    var style = TextStyle()
                    style.foregroundColor = highlightColor
                    style.isBold = true
                    return style
                }()
            )

            let labelStyled: String
            if let color = labelColor {
                labelStyled = ANSIRenderer.render(
                    " " + item.label,
                    with: {
                        var style = TextStyle()
                        style.foregroundColor = color
                        return style
                    }()
                )
            } else {
                labelStyled = " " + item.label
            }

            return shortcutStyled + labelStyled
        }

        switch style {
        case .compact:
            return renderCompact(itemStrings: itemStrings, width: context.availableWidth)

        case .bordered:
            return renderBordered(itemStrings: itemStrings, width: context.availableWidth, context: context)
        }
    }

    /// Aligns content within the given width based on alignment setting.
    ///
    /// - Parameters:
    ///   - itemStrings: The styled item strings to align.
    ///   - width: The total available width.
    /// - Returns: The aligned content string.
    private func alignContent(itemStrings: [String], width: Int) -> String {
        let separator = "  "  // Two spaces between items for non-justified

        switch alignment {
        case .leading:
            let content = " " + itemStrings.joined(separator: separator)
            return content.padToVisibleWidth(width)

        case .trailing:
            let content = itemStrings.joined(separator: separator) + " "
            let contentWidth = content.strippedLength
            let padding = max(0, width - contentWidth)
            return String(repeating: " ", count: padding) + content

        case .center:
            let content = itemStrings.joined(separator: separator)
            let contentWidth = content.strippedLength
            let totalPadding = max(0, width - contentWidth)
            let leftPadding = totalPadding / 2
            let rightPadding = totalPadding - leftPadding
            return String(repeating: " ", count: leftPadding) + content + String(repeating: " ", count: rightPadding)

        case .justified:
            return justifyContent(itemStrings: itemStrings, width: width)
        }
    }

    /// Distributes items evenly across the width (justified alignment).
    ///
    /// Items are distributed so that the space on the left edge, between items,
    /// and on the right edge are all equal.
    ///
    /// - Parameters:
    ///   - itemStrings: The styled item strings to distribute.
    ///   - width: The total available width.
    /// - Returns: The justified content string.
    private func justifyContent(itemStrings: [String], width: Int) -> String {
        guard !itemStrings.isEmpty else {
            return String(repeating: " ", count: width)
        }

        guard itemStrings.count > 1 else {
            // Single item: center it
            let content = itemStrings.first ?? ""
            let contentWidth = content.strippedLength
            let totalPadding = max(0, width - contentWidth)
            let leftPadding = totalPadding / 2
            let rightPadding = totalPadding - leftPadding
            return String(repeating: " ", count: leftPadding) + content + String(repeating: " ", count: rightPadding)
        }

        // Calculate total content width (without gaps)
        let totalContentWidth = itemStrings.reduce(0) { sum, item in
            sum + item.strippedLength
        }

        // For n items, we have n+1 gaps (left edge, between each item, right edge)
        let gapCount = itemStrings.count + 1
        let availableForGaps = max(0, width - totalContentWidth)
        let gapWidth = availableForGaps / gapCount
        let extraSpace = availableForGaps % gapCount

        // Build justified string with equal gaps
        var result = ""

        // Left edge gap (gets extra space if available)
        let leftGapExtra = extraSpace > 0 ? 1 : 0
        result += String(repeating: " ", count: gapWidth + leftGapExtra)

        for (index, item) in itemStrings.enumerated() {
            result += item

            if index < itemStrings.count - 1 {
                // Gap between items
                // Distribute extra space to middle gaps (after left edge took one if available)
                let gapIndex = index + 1  // 0 = left edge, 1..n-1 = between items, n = right edge
                let extra = gapIndex < extraSpace ? 1 : 0
                result += String(repeating: " ", count: gapWidth + extra)
            }
        }

        // Right edge gap
        let rightGapIndex = itemStrings.count
        let rightGapExtra = rightGapIndex < extraSpace ? 1 : 0
        result += String(repeating: " ", count: gapWidth + rightGapExtra)

        // Ensure the result fills the width exactly
        return result.padToVisibleWidth(width)
    }

    /// Renders the compact style (single line with alignment).
    private func renderCompact(itemStrings: [String], width: Int) -> FrameBuffer {
        let line = alignContent(itemStrings: itemStrings, width: width)
        return FrameBuffer(lines: [line])
    }

    /// Renders the bordered style using the current appearance's border style.
    private func renderBordered(itemStrings: [String], width: Int, context: RenderContext) -> FrameBuffer {
        let innerWidth = width - BorderRenderer.borderWidthOverhead
        let content = alignContent(itemStrings: itemStrings, width: innerWidth)

        // Check if we're using block appearance for special rendering
        let isBlockAppearance = context.environment.appearance.rawId == .block
        if isBlockAppearance {
            return renderBlockBordered(content: content, innerWidth: innerWidth, context: context)
        }

        // Standard bordered rendering with regular box-drawing characters
        let border = context.environment.appearance.borderStyle
        let borderColor = context.environment.palette.border

        return FrameBuffer(lines: [
            BorderRenderer.standardTopBorder(style: border, innerWidth: innerWidth, color: borderColor),
            BorderRenderer.standardContentLine(content: content, innerWidth: innerWidth, style: border, color: borderColor),
            BorderRenderer.standardBottomBorder(style: border, innerWidth: innerWidth, color: borderColor),
        ])
    }

    /// Renders block-style status bar with half-block characters.
    private func renderBlockBordered(content: String, innerWidth: Int, context: RenderContext) -> FrameBuffer {
        let statusBarBg = context.environment.palette.statusBarBackground

        return FrameBuffer(lines: [
            BorderRenderer.blockTopBorder(innerWidth: innerWidth, color: statusBarBg),
            BorderRenderer.blockContentLine(content: content, innerWidth: innerWidth, sectionColor: statusBarBg),
            BorderRenderer.blockBottomBorder(innerWidth: innerWidth, color: statusBarBg),
        ])
    }
}

// MARK: - Status Bar Height Helper

extension StatusBar {
    /// The height of the status bar in lines.
    public var height: Int {
        switch style {
        case .compact:
            return 1
        case .bordered:
            return 3
        }
    }
}
