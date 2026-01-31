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
public struct RedPalette: BlockPalette {
    public let id = "red"
    public let name = "Red"

    // Background
    public let background = Color.hex(0x0A0606)

    // Red text hierarchy
    public let foreground = Color.hex(0xFF4444)  // Bright red - primary text
    public let foregroundSecondary = Color.hex(0xCC3333)  // Medium red - secondary text
    public let foregroundTertiary = Color.hex(0x8F2222)  // Dim red - tertiary/muted text

    // Accent
    public let accent = Color.hex(0xFF6666)  // Lighter red for highlights

    // Semantic colors (stay in red family)
    public let success = Color.hex(0xFF8080)  // Light red (success in red theme)
    public let warning = Color.hex(0xFFAA66)  // Orange
    public let error = Color.hex(0xFFFFFF)  // White (stands out as error)
    public let info = Color.hex(0xFF9999)  // Light red

    // UI elements
    public let border = Color.hex(0x5A2D2D)  // Subtle red border

    // Additional backgrounds
    public let statusBarBackground = Color.hex(0x191313)
    public let appHeaderBackground = Color.hex(0x1E0F10)
    public let overlayBackground = Color.hex(0x0A0606)

    public init() {}
}

// MARK: - Convenience Accessors

extension BlockPalette where Self == RedPalette {
    /// Red terminal palette.
    public static var red: RedPalette { RedPalette() }
}
