//
//  StatusBar.swift
//  SwiftTUI
//
//  A status bar that displays keyboard shortcuts and context-sensitive actions.
//  Always rendered at the bottom of the terminal, never dimmed by overlays.
//

import Foundation

// MARK: - Status Bar Style

/// The visual style of the status bar.
public enum TStatusBarStyle: Sendable {
    /// A single line with horizontal padding.
    case compact

    /// Block-style border (like `BorderStyle.block`).
    case bordered
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
/// TStatusBarItem(shortcut: .escape, label: "close") { dismiss() }
/// TStatusBarItem(shortcut: .arrowsUpDown, label: "nav")
/// TStatusBarItem(shortcut: .enter, label: "select", key: .enter)
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

// MARK: - Status Bar Item Protocol

/// A protocol for items that can be displayed in a status bar.
///
/// Implement this protocol to create custom status bar items.
/// The default `TStatusBarItem` already conforms to this protocol.
public protocol TStatusBarItemProtocol: Sendable {
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

    /// Whether this item matches a given key event.
    ///
    /// Override this for complex matching (e.g., arrow keys).
    func matches(_ event: KeyEvent) -> Bool
}

// Default implementation for triggerKey matching
public extension TStatusBarItemProtocol {
    func matches(_ event: KeyEvent) -> Bool {
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
/// TStatusBarItem(shortcut: "q", label: "quit") {
///     app.quit()
/// }
///
/// TStatusBarItem(shortcut: "↑↓", label: "nav", key: .up) // Info only, no action
/// ```
public struct TStatusBarItem: TStatusBarItemProtocol, Identifiable {
    public let id: String
    public let shortcut: String
    public let label: String
    public let triggerKey: Key?

    /// The action to perform when the shortcut is triggered.
    private let action: (@Sendable () -> Void)?

    /// Creates a status bar item with an action.
    ///
    /// - Parameters:
    ///   - shortcut: The shortcut key(s) to display.
    ///   - label: A short description (one word).
    ///   - key: The key that triggers the action (derived from shortcut if not provided).
    ///   - action: The action to perform.
    public init(
        shortcut: String,
        label: String,
        key: Key? = nil,
        action: (@Sendable () -> Void)? = nil
    ) {
        self.id = "\(shortcut)-\(label)"
        self.shortcut = shortcut
        self.label = label
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
    public init(shortcut: String, label: String) {
        self.init(shortcut: shortcut, label: label, key: nil, action: nil)
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
           case .character(let eventChar) = event.key {
            return triggerChar == eventChar
        }

        return event.key == trigger
    }
}

// MARK: - Status Bar Manager

/// Manages the status bar state and context-dependent items.
///
/// The StatusBarManager is a singleton that tracks which items should
/// be displayed based on the current context (focused view, active dialog, etc.).
///
/// # Usage
///
/// ```swift
/// // Push a new context with items
/// StatusBarManager.shared.push(context: "dialog") {
///     TStatusBarItem(shortcut: "⎋", label: "close") { dismiss() }
///     TStatusBarItem(shortcut: "↵", label: "confirm") { confirm() }
/// }
///
/// // Pop the context when done
/// StatusBarManager.shared.pop(context: "dialog")
/// ```
public final class StatusBarManager: @unchecked Sendable {
    /// The shared manager instance.
    public static let shared = StatusBarManager()

    /// Stack of contexts with their items.
    private var contextStack: [(context: String, items: [any TStatusBarItemProtocol])] = []

    /// Global items that are always shown (lowest priority).
    private var globalItems: [any TStatusBarItemProtocol] = []

    /// The current status bar style.
    public var style: TStatusBarStyle = .compact

    /// The highlight color for shortcut keys.
    public var highlightColor: Color = .cyan

    /// The label color.
    public var labelColor: Color? = nil  // Default terminal color

    /// Callback when items change (triggers re-render).
    public var onItemsChanged: (() -> Void)?

    private init() {}

    // MARK: - Global Items

    /// Sets the global status bar items (always shown when no context overrides).
    ///
    /// - Parameter items: The items to set.
    public func setGlobalItems(_ items: [any TStatusBarItemProtocol]) {
        globalItems = items
        notifyChange()
    }

    /// Sets global items using a builder.
    ///
    /// - Parameter builder: A closure that returns items.
    public func setGlobalItems(@StatusBarItemBuilder _ builder: () -> [any TStatusBarItemProtocol]) {
        globalItems = builder()
        notifyChange()
    }

    // MARK: - Context Stack

    /// Pushes a new context with its items onto the stack.
    ///
    /// Items from the most recent context are displayed.
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - items: The items to display for this context.
    public func push(context: String, items: [any TStatusBarItemProtocol]) {
        // Remove existing context with same name (if any)
        contextStack.removeAll { $0.context == context }
        contextStack.append((context, items))
        notifyChange()
    }

    /// Pushes a new context using a builder.
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - builder: A closure that returns items.
    public func push(context: String, @StatusBarItemBuilder _ builder: () -> [any TStatusBarItemProtocol]) {
        push(context: context, items: builder())
    }

    /// Pops a context from the stack.
    ///
    /// - Parameter context: The context identifier to remove.
    public func pop(context: String) {
        contextStack.removeAll { $0.context == context }
        notifyChange()
    }

    /// Clears all contexts (keeps global items).
    public func clearContexts() {
        contextStack.removeAll()
        notifyChange()
    }

    /// Clears everything including global items.
    public func clear() {
        contextStack.removeAll()
        globalItems.removeAll()
        notifyChange()
    }

    // MARK: - Current Items

    /// The currently active items (topmost context or global).
    public var currentItems: [any TStatusBarItemProtocol] {
        if let topContext = contextStack.last {
            return topContext.items
        }
        return globalItems
    }

    /// Whether the status bar has any items to display.
    public var hasItems: Bool {
        !currentItems.isEmpty
    }

    // MARK: - Event Handling

    /// Handles a key event, checking if any current item matches.
    ///
    /// - Parameter event: The key event to handle.
    /// - Returns: True if an item handled the event.
    @discardableResult
    public func handleKeyEvent(_ event: KeyEvent) -> Bool {
        for item in currentItems {
            if item.matches(event) {
                if let statusBarItem = item as? TStatusBarItem {
                    statusBarItem.execute()
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Private

    private func notifyChange() {
        onItemsChanged?()
        AppState.shared.setNeedsRender()
    }
}

// MARK: - Status Bar Item Builder

/// Result builder for creating status bar items.
@resultBuilder
public struct StatusBarItemBuilder {
    public static func buildBlock(_ items: any TStatusBarItemProtocol...) -> [any TStatusBarItemProtocol] {
        items
    }

    public static func buildBlock(_ items: [any TStatusBarItemProtocol]) -> [any TStatusBarItemProtocol] {
        items
    }

    public static func buildArray(_ components: [[any TStatusBarItemProtocol]]) -> [any TStatusBarItemProtocol] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [any TStatusBarItemProtocol]?) -> [any TStatusBarItemProtocol] {
        component ?? []
    }

    public static func buildEither(first component: [any TStatusBarItemProtocol]) -> [any TStatusBarItemProtocol] {
        component
    }

    public static func buildEither(second component: [any TStatusBarItemProtocol]) -> [any TStatusBarItemProtocol] {
        component
    }

    public static func buildExpression(_ expression: any TStatusBarItemProtocol) -> [any TStatusBarItemProtocol] {
        [expression]
    }
}

// MARK: - TStatusBar View

/// A status bar that displays at the bottom of the terminal.
///
/// The status bar shows keyboard shortcuts and their descriptions.
/// It's rendered separately from the main view tree and is never
/// affected by overlays or dimming.
///
/// # Example
///
/// ```swift
/// // The status bar is typically managed via StatusBarManager,
/// // but can also be used directly:
/// TStatusBar(items: [
///     TStatusBarItem(shortcut: "q", label: "quit"),
///     TStatusBarItem(shortcut: "↑↓", label: "nav"),
/// ])
/// ```
public struct TStatusBar: TView {
    /// The items to display.
    public let items: [any TStatusBarItemProtocol]

    /// The visual style.
    public let style: TStatusBarStyle

    /// The highlight color for shortcut keys.
    public let highlightColor: Color

    /// The label color.
    public let labelColor: Color?

    /// Creates a status bar with explicit items.
    ///
    /// - Parameters:
    ///   - items: The items to display.
    ///   - style: The visual style (default: `.compact`).
    ///   - highlightColor: The color for shortcut keys (default: `.cyan`).
    ///   - labelColor: The color for labels (default: nil, terminal default).
    public init(
        items: [any TStatusBarItemProtocol],
        style: TStatusBarStyle = .compact,
        highlightColor: Color = .cyan,
        labelColor: Color? = nil
    ) {
        self.items = items
        self.style = style
        self.highlightColor = highlightColor
        self.labelColor = labelColor
    }

    /// Creates a status bar using the StatusBarManager's current items.
    ///
    /// - Parameter style: The visual style (default: from manager).
    public init(style: TStatusBarStyle? = nil) {
        let manager = StatusBarManager.shared
        self.items = manager.currentItems
        self.style = style ?? manager.style
        self.highlightColor = manager.highlightColor
        self.labelColor = manager.labelColor
    }

    /// Creates a status bar using a builder.
    ///
    /// - Parameters:
    ///   - style: The visual style.
    ///   - highlightColor: The color for shortcut keys.
    ///   - labelColor: The color for labels.
    ///   - builder: A closure that returns items.
    public init(
        style: TStatusBarStyle = .compact,
        highlightColor: Color = .cyan,
        labelColor: Color? = nil,
        @StatusBarItemBuilder _ builder: () -> [any TStatusBarItemProtocol]
    ) {
        self.items = builder()
        self.style = style
        self.highlightColor = highlightColor
        self.labelColor = labelColor
    }

    public var body: Never {
        fatalError("TStatusBar renders via Renderable")
    }
}

// MARK: - TStatusBar Rendering

extension TStatusBar: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        guard !items.isEmpty else {
            return FrameBuffer()
        }

        // Build item strings
        let itemStrings = items.map { item -> String in
            let shortcutStyled = ANSIRenderer.render(item.shortcut, with: {
                var style = TextStyle()
                style.foregroundColor = highlightColor
                style.isBold = true
                return style
            }())

            let labelStyled: String
            if let color = labelColor {
                labelStyled = ANSIRenderer.render(" " + item.label, with: {
                    var style = TextStyle()
                    style.foregroundColor = color
                    return style
                }())
            } else {
                labelStyled = " " + item.label
            }

            return shortcutStyled + labelStyled
        }

        let separator = "  "  // Two spaces between items
        let content = itemStrings.joined(separator: separator)

        switch style {
        case .compact:
            return renderCompact(content: content, width: context.availableWidth)

        case .bordered:
            return renderBordered(content: content, width: context.availableWidth)
        }
    }

    /// Renders the compact style (single line with padding).
    private func renderCompact(content: String, width: Int) -> FrameBuffer {
        let padding = " "
        let paddedContent = padding + content
        let line = paddedContent.padToVisibleWidth(width)
        return FrameBuffer(lines: [line])
    }

    /// Renders the bordered style (block border).
    private func renderBordered(content: String, width: Int) -> FrameBuffer {
        let border = BorderStyle.block
        let innerWidth = width - 2  // Account for left and right border

        let padding = " "
        let paddedContent = padding + content

        // Build the three lines
        let topBorder = String(border.topLeft)
            + String(repeating: border.horizontal, count: innerWidth)
            + String(border.topRight)

        let contentLine = String(border.vertical)
            + paddedContent.padToVisibleWidth(innerWidth)
            + ANSIRenderer.reset  // Prevent color bleeding
            + String(border.vertical)

        let bottomBorder = String(border.bottomLeft)
            + String(repeating: border.horizontal, count: innerWidth)
            + String(border.bottomRight)

        return FrameBuffer(lines: [topBorder, contentLine, bottomBorder])
    }
}

// MARK: - Status Bar Height Helper

extension TStatusBar {
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
