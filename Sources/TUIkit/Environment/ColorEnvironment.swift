//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ColorEnvironment.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitStyling

// MARK: - Foreground Style Environment

/// Environment key for the foreground style.
///
/// When set via `.foregroundStyle(_:)` on any View, this value propagates
/// down through the view hierarchy. Child views can read it from the
/// render context to apply the color.
private struct ForegroundStyleKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

extension EnvironmentValues {
    /// The foreground style (color) for text and other content.
    ///
    /// Set via `.foregroundStyle(_:)` modifier on any View.
    /// Returns `nil` if not explicitly set (use palette default).
    public var foregroundStyle: Color? {
        get { self[ForegroundStyleKey.self] }
        set { self[ForegroundStyleKey.self] = newValue }
    }
}

// MARK: - View Extension for foregroundStyle

extension View {
    /// Sets the foreground style for this view and its children.
    ///
    /// The style propagates through the view hierarchy via the environment.
    /// Child views that render text or other colored content should read
    /// `context.environment.foregroundStyle` and apply it.
    ///
    /// ## Example
    ///
    /// ```swift
    /// VStack {
    ///     Text("Red text")
    ///     Text("Also red")
    /// }
    /// .foregroundStyle(.red)
    /// ```
    ///
    /// - Parameter style: The color to apply as foreground style.
    /// - Returns: A view with the foreground style set.
    public func foregroundStyle(_ style: Color?) -> some View {
        environment(\.foregroundStyle, style)
    }
}
