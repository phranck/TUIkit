//
//  AmberPalette.swift
//  TUIkit
//
//  Classic amber terminal palette (P3 phosphor).
//

/// Classic amber terminal palette (P3 phosphor).
///
/// Inspired by terminals like the IBM 3278 and Wyse 50.
/// Uses a dark background with subtle amber/orange tint.
public struct AmberPalette: Palette {
    public let id = "amber"
    public let name = "Amber"

    // Background hierarchy
    public let background = Color.hex(0x0A0706)  // App background (darkest)
    public let containerBodyBackground = Color.hex(0x251710)  // Container content background
    public let containerCapBackground = Color.hex(0x1E110E)  // Container header/footer background

    // Amber text hierarchy (matching Spotnik)
    public let foreground = Color.hex(0xFFAA00)  // Bright amber - primary text
    public let foregroundSecondary = Color.hex(0xCC8800)  // Medium amber - secondary text
    public let foregroundTertiary = Color.hex(0x8F6600)  // Dim amber - tertiary/muted text

    // Accent colors
    public let accent = Color.hex(0xFFCC33)  // Lighter amber for highlights
    public let accentSecondary = Color.hex(0xCC9900)  // Darker accent

    // Semantic colors (stay in amber family)
    public let success = Color.hex(0xFFCC00)
    public let warning = Color.hex(0xFFE066)  // Light amber
    public let error = Color.hex(0xFF6633)  // Orange-red (contrast)
    public let info = Color.hex(0xFFD966)  // Light amber

    // UI elements
    public let border = Color.hex(0x5A4A2D)  // Subtle amber border
    public let borderFocused = Color.hex(0xFFAA00)  // Bright when focused
    public let selection = Color.hex(0xFFCC33)  // Bright amber for selection text
    public let selectionBackground = Color.hex(0x4D3A1F)  // Dark amber for selection bar bg

    // Additional backgrounds
    public let statusBarBackground = Color.hex(0x191613)
    public let appHeaderBackground = Color.hex(0x1E110E)  // Same as cap
    public let overlayBackground = Color.hex(0x0A0706)  // Dimming overlay
    public var buttonBackground: Color { Color.hex(0x3A2A1D) }  // Lighter amber for buttons

    // Status bar
    public let statusBarForeground = Color.hex(0xFFAA00)
    public let statusBarHighlight = Color.hex(0xFFCC33)

    public init() {}
}

// MARK: - Convenience Accessors

extension Palette where Self == AmberPalette {
    /// Amber terminal palette.
    public static var amber: AmberPalette { AmberPalette() }
}
