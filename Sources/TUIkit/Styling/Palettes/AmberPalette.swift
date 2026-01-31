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
public struct AmberPalette: BlockPalette {
    public let id = "amber"
    public let name = "Amber"

    // Background
    public let background = Color.hex(0x0A0706)

    // Amber text hierarchy (matching Spotnik)
    public let foreground = Color.hex(0xFFAA00)  // Bright amber - primary text
    public let foregroundSecondary = Color.hex(0xCC8800)  // Medium amber - secondary text
    public let foregroundTertiary = Color.hex(0x8F6600)  // Dim amber - tertiary/muted text

    // Accent
    public let accent = Color.hex(0xFFCC33)  // Lighter amber for highlights

    // Semantic colors (stay in amber family)
    public let success = Color.hex(0xFFCC00)
    public let warning = Color.hex(0xFFE066)  // Light amber
    public let error = Color.hex(0xFF6633)  // Orange-red (contrast)
    public let info = Color.hex(0xFFD966)  // Light amber

    // UI elements
    public let border = Color.hex(0x5A4A2D)  // Subtle amber border

    // Additional backgrounds
    public let statusBarBackground = Color.hex(0x191613)
    public let appHeaderBackground = Color.hex(0x1E110E)
    public let overlayBackground = Color.hex(0x0A0706)

    public init() {}
}

// MARK: - Convenience Accessors

extension BlockPalette where Self == AmberPalette {
    /// Amber terminal palette.
    public static var amber: AmberPalette { AmberPalette() }
}
