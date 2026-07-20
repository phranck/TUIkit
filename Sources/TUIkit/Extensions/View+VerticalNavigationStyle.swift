//  🖥️ TUIKit — Terminal UI Kit for Swift
//  View+VerticalNavigationStyle.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Vertical Navigation Style Modifier

extension View {
    /// Sets the vertical (up/down) keyboard navigation style for scrollable
    /// views in this subtree.
    ///
    /// Pass one or more styles to activate them simultaneously. Calling this
    /// modifier replaces the inherited vertical navigation style entirely.
    ///
    /// | Style | Keys |
    /// |-------|------|
    /// | `.arrowKey` | ↑ ↓ Home End PageUp PageDown |
    /// | `.vim` | j k g G Ctrl+d Ctrl+u Ctrl+f Ctrl+b |
    ///
    /// ```swift
    /// // Vim only — arrow keys inactive
    /// List("Items", selection: $sel) { … }
    ///     .verticalNavigationStyle(.vim)
    ///
    /// // Both — all vertical keys active
    /// List("Items", selection: $sel) { … }
    ///     .verticalNavigationStyle(.vim, .arrowKey)
    /// ```
    ///
    /// - Parameter styles: The vertical navigation styles to activate.
    /// - Returns: A view with the specified vertical navigation styles applied.
    public func verticalNavigationStyle(_ styles: VerticalNavigationStyle...) -> some View {
        VerticalNavigationStyleModifier(content: self, styles: Set(styles))
    }
}
