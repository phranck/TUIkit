//  🖥️ TUIKit — Terminal UI Kit for Swift
//  VerticalNavigationStyle.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Vertical Navigation Style

/// The keyboard scheme for vertical (up/down) navigation within scrollable views.
///
/// Pass one or more styles to `.verticalNavigationStyle(_:)` to control which
/// key bindings drive up/down movement inside `List`, `Table`, `Menu`, and
/// any other container that responds to up/down keys. Styles combine freely —
/// passing both enables all keys simultaneously.
///
/// ```swift
/// // Arrow keys only (default)
/// List("Items", selection: $sel) { … }
///
/// // Vim keys only
/// List("Items", selection: $sel) { … }
///     .verticalNavigationStyle(.vim)
///
/// // Both active together
/// List("Items", selection: $sel) { … }
///     .verticalNavigationStyle(.vim, .arrowKey)
/// ```
public enum VerticalNavigationStyle: Hashable, Sendable {
    /// Standard arrow-key navigation: ↑ ↓ Home End PageUp PageDown.
    case arrowKey

    /// Vim-style motion keys: j k g G Ctrl+d Ctrl+u Ctrl+f Ctrl+b.
    case vim
}
