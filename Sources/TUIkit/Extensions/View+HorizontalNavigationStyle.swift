//  🖥️ TUIKit — Terminal UI Kit for Swift
//  View+HorizontalNavigationStyle.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Horizontal Navigation Style Modifier

extension View {
    /// Sets the horizontal (Tab/section) keyboard navigation style for
    /// focusable views in this subtree.
    ///
    /// Pass one or more styles to activate them simultaneously. Calling this
    /// modifier replaces the inherited horizontal navigation style entirely.
    ///
    /// | Style | Keys |
    /// |-------|------|
    /// | `.tab` | Tab (next), Shift+Tab (previous) |
    /// | `.vim` | l (next), h (previous) |
    ///
    /// ```swift
    /// // Vim only — Tab inactive
    /// VStack { … }
    ///     .horizontalNavigationStyle(.vim)
    ///
    /// // Both — Tab and h/l all active
    /// VStack { … }
    ///     .horizontalNavigationStyle(.tab, .vim)
    /// ```
    ///
    /// - Parameter styles: The horizontal navigation styles to activate.
    /// - Returns: A view with the specified horizontal navigation styles applied.
    public func horizontalNavigationStyle(_ styles: HorizontalNavigationStyle...) -> some View {
        HorizontalNavigationStyleModifier(content: self, styles: Set(styles))
    }
}
