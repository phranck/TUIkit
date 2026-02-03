//  🖥️ TUIKit — Terminal UI Kit for Swift
//  View+Modifier.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

// MARK: - View Modifier Extension

extension View {
    /// Applies a modifier to this view.
    ///
    /// - Parameter modifier: The modifier to apply.
    /// - Returns: A modified view.
    public func modifier<M: ViewModifier>(_ modifier: M) -> ModifiedView<Self, M> {
        ModifiedView(content: self, modifier: modifier)
    }
}
