//
//  GreenPalette.swift
//  TUIkit
//
//  Classic green terminal palette (P1 phosphor).
//

/// Classic green terminal palette (P1 phosphor).
///
/// Inspired by early CRT monitors like the IBM 5151 and Apple II.
/// Uses a dark background with subtle green tint.
public struct GreenPalette: Palette {
    public let id = "green"
    public let name = "Green"

    // Background hierarchy
    public let background = Color.hex(0x060A07)  // App background (darkest)
    public let backgroundSecondary = Color.hex(0x0E271C)  // Container body background (brighter)
    public let backgroundTertiary = Color.hex(0x0A1B13)  // Header/footer background

    // Green text hierarchy
    public let foreground = Color.hex(0x33FF33)  // Bright green - primary text
    public let foregroundSecondary = Color.hex(0x27C227)  // Medium green - secondary text
    public let foregroundTertiary = Color.hex(0x1F8F1F)  // Dim green - tertiary/muted text

    // Accent colors
    public let accent = Color.hex(0x66FF66)  // Lighter green for highlights
    public let accentSecondary = Color.hex(0x00CC00)  // Darker accent

    // Semantic colors (stay in green family)
    public let success = Color.hex(0x33FF33)
    public let warning = Color.hex(0xCCFF33)  // Yellow-green
    public let error = Color.hex(0xFF6633)  // Orange-red (contrast)
    public let info = Color.hex(0x33FFCC)  // Cyan-green

    // UI elements
    public let border = Color.hex(0x2D5A2D)  // Subtle green border
    public let borderFocused = Color.hex(0x33FF33)  // Bright when focused
    public let selection = Color.hex(0x66FF66)  // Bright green for selection text
    public let selectionBackground = Color.hex(0x1A4D1A)  // Dark green for selection bar bg

    // Status bar
    public let statusBarBackground = Color.hex(0x0F2215)  // Dark green for status bar
    public let statusBarForeground = Color.hex(0x2FDD2F)  // Slightly dimmer than primary foreground
    public let statusBarHighlight = Color.hex(0x66FF66)

    // Container colors for block appearance
    public var containerBackground: Color { backgroundSecondary }  // #0E271C - body
    public var containerHeaderBackground: Color { backgroundTertiary }  // #0A1B13 - header/footer
    public var buttonBackground: Color { Color.hex(0x145523) }  // Lighter green for buttons

    public init() {}
}

// MARK: - Convenience Accessors

extension Palette where Self == GreenPalette {
    /// The default palette (green).
    public static var `default`: GreenPalette { GreenPalette() }
    /// Green terminal palette.
    public static var green: GreenPalette { GreenPalette() }
}
