//  🖥️ TUIKit — Terminal UI Kit for Swift
//  HorizontalNavigationStyle.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Horizontal Navigation Style

/// The keyboard scheme for horizontal (Tab/section) navigation between focusable views.
///
/// Pass one or more styles to `.horizontalNavigationStyle(_:)` to control which
/// key bindings cycle focus between interactive elements and sections. Styles
/// combine freely — passing both enables all keys simultaneously.
///
/// ```swift
/// // Tab only (default)
/// VStack { … }
///
/// // Vim keys only (h = previous, l = next)
/// VStack { … }
///     .horizontalNavigationStyle(.vim)
///
/// // Both active together
/// VStack { … }
///     .horizontalNavigationStyle(.tab, .vim)
/// ```
public enum HorizontalNavigationStyle: Hashable, Sendable {
    /// Standard Tab / Shift+Tab navigation: Tab = next, Shift+Tab = previous.
    case tab

    /// Vim-style horizontal keys: l = next (Tab), h = previous (Shift+Tab).
    case vim
}
