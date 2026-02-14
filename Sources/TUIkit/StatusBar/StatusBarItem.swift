//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StatusBarItem.swift
//
//  Created by LAYERED.work
//  License: MIT  style, shortcut symbols, and system items.
//

// MARK: - Status Bar Style

/// The visual style of the status bar.
public enum StatusBarStyle: Sendable {
    /// A single line with horizontal padding.
    case compact

    /// Bordered with the current appearance's border style.
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
public struct StatusBarItem: StatusBarItemProtocol, Identifiable, @unchecked Sendable {
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
    private let action: (() -> Void)?

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
        action: (() -> Void)? = nil
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
}

// MARK: - Public API

public extension StatusBarItem {
    /// Executes the item's action.
    func execute() {
        action?()
    }

    /// Override matching for special cases.
    func matches(_ event: KeyEvent) -> Bool {
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

// MARK: - Private Helpers

private extension StatusBarItem {
    /// Maps common shortcut symbols to Key values.
    static func keyFromShortcut(_ shortcut: String) -> Key? {
        switch shortcut {
        // Special keys
        case Shortcut.escape, "esc", "escape":
            return .escape
        case Shortcut.enter, Shortcut.returnKey, "enter", "return":
            return .enter
        case Shortcut.tab, "tab":
            return .tab
        case Shortcut.backspace, "backspace", "del":
            return .backspace
        case Shortcut.delete:
            return .delete
        case Shortcut.space, "space":
            return .space

        // Arrow keys
        case Shortcut.arrowUp:
            return .up
        case Shortcut.arrowDown:
            return .down
        case Shortcut.arrowLeft:
            return .left
        case Shortcut.arrowRight:
            return .right

        // Navigation keys
        case Shortcut.home:
            return .home
        case Shortcut.end:
            return .end
        case Shortcut.pageUp:
            return .pageUp
        case Shortcut.pageDown:
            return .pageDown

        // Function keys
        case Shortcut.f1:
            return .f1
        case Shortcut.f2:
            return .f2
        case Shortcut.f3:
            return .f3
        case Shortcut.f4:
            return .f4
        case Shortcut.f5:
            return .f5
        case Shortcut.f6:
            return .f6
        case Shortcut.f7:
            return .f7
        case Shortcut.f8:
            return .f8
        case Shortcut.f9:
            return .f9
        case Shortcut.f10:
            return .f10
        case Shortcut.f11:
            return .f11
        case Shortcut.f12:
            return .f12

        default:
            return nil
        }
    }
}
