//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StatusBarItemBuilder.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Status Bar Item Builder

/// A result builder that constructs arrays of status bar items.
///
/// `StatusBarItemBuilder` enables the declarative syntax for defining multiple
/// items in a status bar. You don't use this type directly; instead, the
/// `@StatusBarItemBuilder` attribute is applied to closures that define
/// status bar content.
///
/// ## Overview
///
/// When you write:
///
/// ```swift
/// .statusBarItems {
///     StatusBarItem(shortcut: .arrowsUpDown, label: "navigate")
///     StatusBarItem(shortcut: .enter, label: "select", key: .enter)
///     StatusBarItem(shortcut: .escape, label: "back") { goBack() }
/// }
/// ```
///
/// The `@StatusBarItemBuilder` attribute transforms this closure into an array
/// of ``StatusBarItemProtocol`` conforming items that the status bar can display.
///
/// ## Supported Control Flow
///
/// The builder supports:
/// - Multiple item expressions
/// - `if`/`else` conditionals
/// - `if let` optional binding
/// - `for`...`in` loops
///
/// ## See Also
///
/// - ``StatusBarItem``
/// - ``View/statusBarItems(_:_:)``
@resultBuilder
public struct StatusBarItemBuilder {
}

// MARK: - Public API

public extension StatusBarItemBuilder {
    /// Combines multiple item arrays into a single flat array.
    static func buildBlock(_ components: [any StatusBarItemProtocol]...) -> [any StatusBarItemProtocol] {
        components.flatMap { $0 }
    }

    /// Combines an array of item arrays (from `for` loops).
    static func buildArray(_ components: [[any StatusBarItemProtocol]]) -> [any StatusBarItemProtocol] {
        components.flatMap { $0 }
    }

    /// Handles optional item arrays (from `if` without `else`).
    static func buildOptional(_ component: [any StatusBarItemProtocol]?) -> [any StatusBarItemProtocol] {
        component ?? []
    }

    /// Handles the first branch of an `if`/`else`.
    static func buildEither(first component: [any StatusBarItemProtocol]) -> [any StatusBarItemProtocol] {
        component
    }

    /// Handles the second branch of an `if`/`else`.
    static func buildEither(second component: [any StatusBarItemProtocol]) -> [any StatusBarItemProtocol] {
        component
    }

    /// Wraps a single item into an array.
    static func buildExpression(_ expression: any StatusBarItemProtocol) -> [any StatusBarItemProtocol] {
        [expression]
    }
}
