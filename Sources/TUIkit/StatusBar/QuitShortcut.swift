//  🖥️ TUIKit — Terminal UI Kit for Swift
//  QuitShortcut.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Quit Shortcut

/// Defines the keyboard shortcut used to quit the application.
///
/// By default, TUIkit uses `q` to quit. You can change this by setting
/// a different `QuitShortcut` on the status bar state:
///
/// ```swift
/// statusBar.quitShortcut = .escape
/// statusBar.quitShortcut = .ctrlQ
/// statusBar.quitShortcut = QuitShortcut(
///     key: .f12,
///     shortcutSymbol: Shortcut.f12,
///     label: "exit"
/// )
/// ```
///
/// The status bar automatically updates to display the configured shortcut.
public struct QuitShortcut: Sendable {
    /// The key that triggers the quit action.
    public let key: Key

    /// Whether the Ctrl modifier is required.
    public let ctrl: Bool

    /// The symbol displayed in the status bar (e.g., `"q"`, `"⎋"`, `"⌃q"`).
    public let shortcutSymbol: String

    /// The label displayed next to the shortcut symbol (e.g., `"quit"`).
    public let label: String

    /// Creates a custom quit shortcut.
    ///
    /// - Parameters:
    ///   - key: The key that triggers quit.
    ///   - ctrl: Whether Ctrl must be held (default: `false`).
    ///   - shortcutSymbol: The symbol shown in the status bar.
    ///   - label: The label shown next to the symbol (default: `"quit"`).
    public init(
        key: Key,
        ctrl: Bool = false,
        shortcutSymbol: String,
        label: String = "quit"
    ) {
        self.key = key
        self.ctrl = ctrl
        self.shortcutSymbol = shortcutSymbol
        self.label = label
    }
}

// MARK: - Presets

extension QuitShortcut {
    /// The default quit shortcut: `q` (matches both `q` and `Q`).
    public static let q = QuitShortcut(
        key: .character("q"),
        shortcutSymbol: "q",
        label: "quit"
    )

    /// Quit with the Escape key (`⎋`).
    public static let escape = QuitShortcut(
        key: .escape,
        shortcutSymbol: Shortcut.escape,
        label: "quit"
    )

    /// Quit with Ctrl+Q (`⌃q`).
    public static let ctrlQ = QuitShortcut(
        key: .character("q"),
        ctrl: true,
        shortcutSymbol: Shortcut.ctrl("q"),
        label: "quit"
    )

    /// Quit with Ctrl+C (`⌃c`).
    public static let ctrlC = QuitShortcut(
        key: .character("c"),
        ctrl: true,
        shortcutSymbol: Shortcut.ctrl("c"),
        label: "quit"
    )
}

// MARK: - Key Matching

extension QuitShortcut {
    /// Returns whether the given key event matches this quit shortcut.
    ///
    /// For character keys without Ctrl, matching is case-insensitive
    /// (e.g., `.q` matches both `q` and `Q`).
    ///
    /// - Parameter event: The key event to check.
    /// - Returns: `true` if the event matches this shortcut.
    public func matches(_ event: KeyEvent) -> Bool {
        if ctrl {
            return event.ctrl && event.key == key
        }

        // Case-insensitive matching for character keys
        if case .character(let expected) = key,
           case .character(let actual) = event.key {
            return !event.ctrl && actual.lowercased() == expected.lowercased()
        }

        return event.key == key && !event.ctrl
    }
}
