//  🖥️ TUIKit — Terminal UI Kit for Swift
//  SemanticColor.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A token that names a palette property.
///
/// `SemanticColor` is the value stored inside `Color.ColorValue.semantic`.
/// At render time ``Color/resolve(with:)`` maps the token to the concrete
/// ``Color`` returned by the current ``Palette``.
///
/// This enables views to declare palette-relative colors in their `body`
/// without needing a ``RenderContext``:
///
/// ```swift
/// Text("Hello").foregroundStyle(.palette.accent)
/// ```
enum SemanticColor: String, Sendable, Equatable {
    // Background
    case background
    case statusBarBackground
    case appHeaderBackground
    case overlayBackground

    // Foreground
    case foreground
    case foregroundSecondary
    case foregroundTertiary
    case foregroundQuaternary

    // Accent
    case accent

    // Status
    case success
    case warning
    case error
    case info

    // UI Elements
    case border
}

// MARK: - Color Resolution

extension SemanticColor {
    /// Resolves this token to a concrete color using the given palette.
    ///
    /// - Parameter palette: The palette to read from.
    /// - Returns: The concrete ``Color`` from the palette.
    func resolve(with palette: any Palette) -> Color {
        switch self {
        case .background: palette.background
        case .statusBarBackground: palette.statusBarBackground
        case .appHeaderBackground: palette.appHeaderBackground
        case .overlayBackground: palette.overlayBackground
        case .foreground: palette.foreground
        case .foregroundSecondary: palette.foregroundSecondary
        case .foregroundTertiary: palette.foregroundTertiary
        case .foregroundQuaternary: palette.foregroundQuaternary
        case .accent: palette.accent
        case .success: palette.success
        case .warning: palette.warning
        case .error: palette.error
        case .info: palette.info
        case .border: palette.border
        }
    }
}
