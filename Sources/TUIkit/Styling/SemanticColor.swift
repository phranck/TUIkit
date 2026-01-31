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
    // Background (Palette)
    case background
    case statusBarBackground
    case appHeaderBackground
    case overlayBackground

    // Background (BlockPalette)
    case surfaceBackground
    case surfaceHeaderBackground
    case elevatedBackground

    // Foreground
    case foreground
    case foregroundSecondary
    case foregroundTertiary

    // Accent
    case accent

    // Status
    case success
    case warning
    case error
    case info

    // UI Elements
    case border

    /// Resolves this token to a concrete color using the given palette.
    ///
    /// For ``BlockPalette``-specific tokens (`surfaceBackground`,
    /// `surfaceHeaderBackground`, `elevatedBackground`), the palette is
    /// cast to ``BlockPalette``. If the cast fails, `background` is used
    /// as fallback.
    ///
    /// - Parameter palette: The palette to read from.
    /// - Returns: The concrete ``Color`` from the palette.
    func resolve(with palette: any Palette) -> Color {
        switch self {
        // Palette properties
        case .background: palette.background
        case .statusBarBackground: palette.statusBarBackground
        case .appHeaderBackground: palette.appHeaderBackground
        case .overlayBackground: palette.overlayBackground
        case .foreground: palette.foreground
        case .foregroundSecondary: palette.foregroundSecondary
        case .foregroundTertiary: palette.foregroundTertiary
        case .accent: palette.accent
        case .success: palette.success
        case .warning: palette.warning
        case .error: palette.error
        case .info: palette.info
        case .border: palette.border

        // BlockPalette properties (fallback to background)
        case .surfaceBackground:
            (palette as? any BlockPalette)?.surfaceBackground ?? palette.background
        case .surfaceHeaderBackground:
            (palette as? any BlockPalette)?.surfaceHeaderBackground ?? palette.background
        case .elevatedBackground:
            (palette as? any BlockPalette)?.elevatedBackground ?? palette.background
        }
    }
}
