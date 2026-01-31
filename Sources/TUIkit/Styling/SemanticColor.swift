//
//  SemanticColor.swift
//  TUIkit
//
//  Palette-relative color tokens resolved at render time.
//

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
/// Text("Hello").foregroundColor(.palette.accent)
/// ```
enum SemanticColor: String, Sendable, Equatable {
    // Background
    case background
    case containerBodyBackground
    case containerCapBackground
    case buttonBackground
    case statusBarBackground
    case appHeaderBackground
    case overlayBackground

    // Foreground
    case foreground
    case foregroundSecondary
    case foregroundTertiary
    case foregroundPlaceholder

    // Accent
    case accent
    case accentSecondary

    // Status
    case success
    case warning
    case error
    case info

    // UI Elements
    case border
    case borderFocused
    case separator
    case selection
    case selectionBackground
    case disabled

    // Status Bar
    case statusBarForeground
    case statusBarHighlight

    /// Resolves this token to a concrete color using the given palette.
    ///
    /// - Parameter palette: The palette to read from.
    /// - Returns: The concrete ``Color`` from the palette.
    func resolve(with palette: any Palette) -> Color {
        switch self {
        case .background: palette.background
        case .containerBodyBackground: palette.containerBodyBackground
        case .containerCapBackground: palette.containerCapBackground
        case .buttonBackground: palette.buttonBackground
        case .statusBarBackground: palette.statusBarBackground
        case .appHeaderBackground: palette.appHeaderBackground
        case .overlayBackground: palette.overlayBackground
        case .foreground: palette.foreground
        case .foregroundSecondary: palette.foregroundSecondary
        case .foregroundTertiary: palette.foregroundTertiary
        case .foregroundPlaceholder: palette.foregroundPlaceholder
        case .accent: palette.accent
        case .accentSecondary: palette.accentSecondary
        case .success: palette.success
        case .warning: palette.warning
        case .error: palette.error
        case .info: palette.info
        case .border: palette.border
        case .borderFocused: palette.borderFocused
        case .separator: palette.separator
        case .selection: palette.selection
        case .selectionBackground: palette.selectionBackground
        case .disabled: palette.disabled
        case .statusBarForeground: palette.statusBarForeground
        case .statusBarHighlight: palette.statusBarHighlight
        }
    }
}
