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
public struct WhitePalette: Palette {
    public let id = "white"
    public let name = "White"

    // Background hierarchy
    public let background = Color.hex(0x06070A)  // App background (darkest)
    public let containerBodyBackground = Color.hex(0x111A2A)  // Container content background
    public let containerCapBackground = Color.hex(0x0D131D)  // Container header/footer background

    // White/gray text hierarchy
    public let foreground = Color.hex(0xE8E8E8)  // Bright white - primary text
    public let foregroundSecondary = Color.hex(0xB0B0B0)  // Medium gray - secondary text
    public let foregroundTertiary = Color.hex(0x787878)  // Dim gray - tertiary/muted text

    // Accent colors
    public let accent = Color.hex(0xFFFFFF)  // Pure white for highlights
    public let accentSecondary = Color.hex(0xC0C0C0)  // Light gray accent

    // Semantic colors (subtle tints)
    public let success = Color.hex(0xC0FFC0)  // Slight green tint
    public let warning = Color.hex(0xFFE0A0)  // Slight amber tint
    public let error = Color.hex(0xFFA0A0)  // Slight red tint
    public let info = Color.hex(0xA0D0FF)  // Slight blue tint

    // UI elements
    public let border = Color.hex(0x484848)  // Subtle gray border
    public let borderFocused = Color.hex(0xE8E8E8)  // Bright when focused
    public let selection = Color.hex(0xFFFFFF)  // White for selection text
    public let selectionBackground = Color.hex(0x3A3A3A)  // Dark gray for selection bar bg

    // Additional backgrounds
    public let statusBarBackground = Color.hex(0x131619)
    public let appHeaderBackground = Color.hex(0x0D131D)  // Same as cap
    public let overlayBackground = Color.hex(0x06070A)  // Dimming overlay
    public var buttonBackground: Color { Color.hex(0x1D2535) }  // Lighter gray for buttons

    // Status bar
    public let statusBarForeground = Color.hex(0xDCDCDC)  // Slightly dimmer than primary foreground
    public let statusBarHighlight = Color.hex(0xFFFFFF)

    public init() {}
}

// MARK: - Convenience Accessors

extension Palette where Self == WhitePalette {
    /// White terminal palette.
    public static var white: WhitePalette { WhitePalette() }
}
