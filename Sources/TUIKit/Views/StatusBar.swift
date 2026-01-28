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

    /// Whether this item matches a given key event.
    ///
    /// Override this for complex matching (e.g., arrow keys).
    func matches(_ event: KeyEvent) -> Bool
}

// Default implementation for triggerKey matching
public extension StatusBarItemProtocol {
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
/// StatusBarItem(shortcut: "q", label: "quit") {
///     app.quit()
/// }
///
/// StatusBarItem(shortcut: "↑↓", label: "nav", key: .up) // Info only, no action
/// ```
public struct StatusBarItem: StatusBarItemProtocol, Identifiable {
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
           case .character(let eventChar) = event.key {
            return triggerChar == eventChar
        }

        return event.key == trigger
    }
}

// MARK: - Status Bar Item Builder

/// Result builder for creating status bar items.
@resultBuilder
public struct StatusBarItemBuilder {
    public static func buildBlock(_ components: [any StatusBarItemProtocol]...) -> [any StatusBarItemProtocol] {
        components.flatMap { $0 }
    }

    public static func buildArray(_ components: [[any StatusBarItemProtocol]]) -> [any StatusBarItemProtocol] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [any StatusBarItemProtocol]?) -> [any StatusBarItemProtocol] {
        component ?? []
    }

    public static func buildEither(first component: [any StatusBarItemProtocol]) -> [any StatusBarItemProtocol] {
        component
    }

    public static func buildEither(second component: [any StatusBarItemProtocol]) -> [any StatusBarItemProtocol] {
        component
    }

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
///                 StatusBarItem(shortcut: "q", label: "quit"),
///                 StatusBarItem(shortcut: "↑↓", label: "nav"),
///             ])
///         }
///     }
/// }
/// ```
public struct StatusBar: View {
    /// The items to display.
    public let items: [any StatusBarItemProtocol]

    /// The visual style.
    public let style: StatusBarStyle

    /// The horizontal alignment of items.
    public let alignment: StatusBarAlignment

    /// The highlight color for shortcut keys.
    public let highlightColor: Color

    /// The label color.
    public let labelColor: Color?

    /// Creates a status bar with explicit items.
    ///
    /// - Parameters:
    ///   - items: The items to display.
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
        self.items = items
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
        self.items = builder()
        self.style = style
        self.alignment = alignment
        self.highlightColor = highlightColor
        self.labelColor = labelColor
    }

    public var body: Never {
        fatalError("StatusBar renders via Renderable")
    }
}

// MARK: - StatusBar Rendering

extension StatusBar: Renderable {
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

        switch style {
        case .compact:
            return renderCompact(itemStrings: itemStrings, width: context.availableWidth)

        case .bordered:
            return renderBordered(itemStrings: itemStrings, width: context.availableWidth)
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

    /// Renders the bordered style (block border with alignment).
    private func renderBordered(itemStrings: [String], width: Int) -> FrameBuffer {
        let border = BorderStyle.block
        let innerWidth = width - 2  // Account for left and right border

        let content = alignContent(itemStrings: itemStrings, width: innerWidth)

        // Build the three lines
        let topBorder = String(border.topLeft)
            + String(repeating: border.horizontal, count: innerWidth)
            + String(border.topRight)

        let contentLine = String(border.vertical)
            + content
            + ANSIRenderer.reset  // Prevent color bleeding
            + String(border.vertical)

        let bottomBorder = String(border.bottomLeft)
            + String(repeating: border.horizontal, count: innerWidth)
            + String(border.bottomRight)

        return FrameBuffer(lines: [topBorder, contentLine, bottomBorder])
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
