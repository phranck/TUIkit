//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TextCursorStyleEnvironment.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitStyling

// MARK: - Environment Key

/// Environment key for the text cursor style.
private struct TextCursorStyleKey: EnvironmentKey {
    static let defaultValue = TextCursorStyle()
}

extension EnvironmentValues {
    /// The text cursor style for text fields.
    ///
    /// Set this value using the `.textCursor(_:)` modifier:
    ///
    /// ```swift
    /// TextField("Name", text: $name)
    ///     .textCursor(.bar, animation: .blink)
    /// ```
    public var textCursorStyle: TextCursorStyle {
        get { self[TextCursorStyleKey.self] }
        set { self[TextCursorStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Sets the text cursor style for text fields within this view.
    ///
    /// Use this modifier to customize the cursor appearance in ``TextField``
    /// and ``SecureField`` components.
    ///
    /// ```swift
    /// TextField("Name", text: $name)
    ///     .textCursor(.bar)
    /// ```
    ///
    /// - Parameter style: The cursor style to use.
    /// - Returns: A view with the cursor style applied.
    public func textCursor(_ style: TextCursorStyle) -> some View {
        environment(\.textCursorStyle, style)
    }

    /// Sets the text cursor style with separate shape, animation, and speed parameters.
    ///
    /// Use this modifier when you want to specify shape, animation, and speed:
    ///
    /// ```swift
    /// TextField("Code", text: $code)
    ///     .textCursor(.underscore, animation: .blink, speed: .fast)
    /// ```
    ///
    /// - Parameters:
    ///   - shape: The cursor shape.
    ///   - animation: The cursor animation. Defaults to `.pulse`.
    ///   - speed: The animation speed. Defaults to `.regular`.
    /// - Returns: A view with the cursor style applied.
    public func textCursor(
        _ shape: TextCursorStyle.Shape,
        animation: TextCursorStyle.Animation = .pulse,
        speed: TextCursorStyle.Speed = .regular
    ) -> some View {
        environment(\.textCursorStyle, TextCursorStyle(shape: shape, animation: animation, speed: speed))
    }
}
