//  🖥️ TUIKit — Terminal UI Kit for Swift
//  View+Modifier.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - View Modifier Extension

extension View {
    /// Applies a modifier to this view and returns a new view.
    ///
    /// - Parameter modifier: The modifier to apply to this view.
    /// - Returns: A new view with the modifier applied.
    public func modifier<M>(_ modifier: M) -> ModifiedContent<Self, M> {
        ModifiedContent(content: self, modifier: modifier)
    }
}
