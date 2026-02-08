//  🖥️ TUIKit — Terminal UI Kit for Swift
//  View+ListRowSeparator.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - List Row Separator Modifier

extension View {
    /// Sets the visibility of row separators within a list.
    ///
    /// This modifier exists for SwiftUI API compatibility but has no visual effect
    /// in TUIkit. Terminal-based UIs do not support fine-grained separator styling.
    ///
    /// A warning is logged to stderr the first time this modifier is used.
    ///
    /// # Example
    ///
    /// ```swift
    /// List {
    ///     ForEach(items) { item in
    ///         Text(item.name)
    ///             .listRowSeparator(.hidden)  // No effect in TUIkit
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - visibility: The visibility of the separator.
    ///   - edges: The edges where separators should be shown. Default is `.all`.
    /// - Returns: The view unchanged (separators are not supported).
    public func listRowSeparator(_ visibility: Visibility, edges: VerticalEdge.Set = .all) -> some View {
        ListRowSeparatorModifier(content: self, visibility: visibility, edges: edges)
    }
}
