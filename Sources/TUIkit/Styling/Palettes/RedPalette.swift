//
//  RedPalette.swift
//  TUIkit
//
//  Red terminal palette.
//

/// Red terminal palette.
///
/// Less common but used in some military and specialized applications.
/// Night-vision friendly with reduced eye strain in dark environments.
public struct RedPalette: Palette {
    public let id = "red"
    public let name = "Red"

    // Background hierarchy
    public let background = Color.hex(0x0A0606)  // App background (darkest)
    public let containerBodyBackground = Color.hex(0x281112)  // Container content background
    public let containerCapBackground = Color.hex(0x1E0F10)  // Container header/footer background

    // Red text hierarchy
    public let foreground = Color.hex(0xFF4444)  // Bright red - primary text
    public let foregroundSecondary = Color.hex(0xCC3333)  // Medium red - secondary text
    public let foregroundTertiary = Color.hex(0x8F2222)  // Dim red - tertiary/muted text

    // Accent colors
    public let accent = Color.hex(0xFF6666)  // Lighter red for highlights
    public let accentSecondary = Color.hex(0xCC4444)  // Darker accent

    // Semantic colors (stay in red family)
    public let success = Color.hex(0xFF8080)  // Light red (success in red theme)
    public let warning = Color.hex(0xFFAA66)  // Orange
    public let error = Color.hex(0xFFFFFF)  // White (stands out as error)
    public let info = Color.hex(0xFF9999)  // Light red

    // UI elements
    public let border = Color.hex(0x5A2D2D)  // Subtle red border
    public let borderFocused = Color.hex(0xFF4444)  // Bright when focused
    public let selection = Color.hex(0xFF6666)  // Bright red for selection text
    public let selectionBackground = Color.hex(0x4D1F1F)  // Dark red for selection bar bg

    // Additional backgrounds
    public let statusBarBackground = Color.hex(0x191313)
    public let appHeaderBackground = Color.hex(0x1E0F10)  // Same as cap
    public let overlayBackground = Color.hex(0x0A0606)  // Dimming overlay
    public var buttonBackground: Color { Color.hex(0x3A1F22) }  // Lighter red for buttons

    // Status bar
    public let statusBarForeground = Color.hex(0xF23B3B)  // Slightly dimmer than primary foreground
    public let statusBarHighlight = Color.hex(0xFF6666)

    public init() {}
}

// MARK: - Convenience Accessors

extension Palette where Self == RedPalette {
    /// Red terminal palette.
    public static var red: RedPalette { RedPalette() }
}
