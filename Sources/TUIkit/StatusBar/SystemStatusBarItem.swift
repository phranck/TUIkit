//  🖥️ TUIKit — Terminal UI Kit for Swift
//  SystemStatusBarItem.swift
//
//  Created by LAYERED.work
//  License: MIT

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
}

// MARK: - Public API

public extension SystemStatusBarItem {
    /// Creates system items with custom actions.
    ///
    /// - Parameters:
    ///   - onQuit: Action for quit (default: exits app).
    ///   - onAppearance: Action for appearance cycling (optional).
    ///   - onTheme: Action for theme cycling (optional).
    /// - Returns: Array of configured system items.
    static func items(
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
