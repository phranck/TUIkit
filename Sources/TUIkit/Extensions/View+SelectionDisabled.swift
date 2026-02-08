//  🖥️ TUIKit — Terminal UI Kit for Swift
//  View+SelectionDisabled.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Selection Disabled Modifier

extension View {
    /// Disables selection for this view within a List.
    ///
    /// When applied to a list row, focus navigation will skip over this row
    /// and it cannot be selected. The row renders with dimmed styling to
    /// indicate it is not selectable.
    ///
    /// # Example
    ///
    /// ```swift
    /// List(selection: $selection) {
    ///     ForEach(items) { item in
    ///         Text(item.name)
    ///             .selectionDisabled(item.isLocked)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter isDisabled: Whether selection should be disabled. Default is `true`.
    /// - Returns: A view with selection disabled state applied.
    public func selectionDisabled(_ isDisabled: Bool = true) -> some View {
        SelectionDisabledModifier(content: self, isDisabled: isDisabled)
    }
}
