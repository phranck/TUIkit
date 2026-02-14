//  🖥️ TUIKit — Terminal UI Kit for Swift
//  String+ANSI.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - Persistent Background

extension String {
    /// Applies a persistent background color that survives inner ANSI resets.
    ///
    /// If `color` is `nil`, the string is returned unchanged.
    ///
    /// - Parameter color: The background color, or `nil` for no change.
    /// - Returns: The string with persistent background applied, or unchanged if `color` is `nil`.
    func withPersistentBackground(_ color: Color?) -> String {
        guard let color else { return self }
        return ANSIRenderer.applyPersistentBackground(self, color: color)
    }
}
