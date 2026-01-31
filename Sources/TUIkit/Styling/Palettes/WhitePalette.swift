//
//  WhitePalette.swift
//  TUIkit
//
//  Classic white terminal palette (P4 phosphor).
//

/// Classic white terminal palette (P4 phosphor).
///
/// Inspired by terminals like the DEC VT100 and VT220.
/// Uses a dark background with subtle cool/blue tint.
public struct WhitePalette: BlockPalette {
    public let id = "white"
    public let name = "White"

    // Background
    public let background = Color.hex(0x06070A)

    // White/gray text hierarchy
    public let foreground = Color.hex(0xE8E8E8)  // Bright white - primary text
    public let foregroundSecondary = Color.hex(0xB0B0B0)  // Medium gray - secondary text
    public let foregroundTertiary = Color.hex(0x787878)  // Dim gray - tertiary/muted text

    // Accent
    public let accent = Color.hex(0xFFFFFF)  // Pure white for highlights

    // Semantic colors (subtle tints)
    public let success = Color.hex(0xC0FFC0)  // Slight green tint
    public let warning = Color.hex(0xFFE0A0)  // Slight amber tint
    public let error = Color.hex(0xFFA0A0)  // Slight red tint
    public let info = Color.hex(0xA0D0FF)  // Slight blue tint

    // UI elements
    public let border = Color.hex(0x484848)  // Subtle gray border

    // Additional backgrounds
    public let statusBarBackground = Color.hex(0x131619)
    public let appHeaderBackground = Color.hex(0x0D131D)
    public let overlayBackground = Color.hex(0x06070A)

    public init() {}
}

// MARK: - Convenience Accessors

extension BlockPalette where Self == WhitePalette {
    /// White terminal palette.
    public static var white: WhitePalette { WhitePalette() }
}
