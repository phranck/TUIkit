//  BluePalette.swift
//  TUIkit — Terminal UI Framework for Swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

/// Blue VFD terminal palette.
///
/// Inspired by vintage vacuum fluorescent displays (VFDs) found in
/// audio equipment, cash registers, and instrument panels. Uses the
/// characteristic bright cyan-blue glow on a near-black background.
public struct BluePalette: Palette {
    public let id = "blue"
    public let name = "Blue"

    // Background hierarchy
    public let background = Color.hex(0x060708)  // App background (darkest)
    public let containerBodyBackground = Color.hex(0x0E1825)  // Container content background
    public let containerCapBackground = Color.hex(0x0A121C)  // Container header/footer background

    // Blue text hierarchy
    public let foreground = Color.hex(0x00AAFF)  // Bright VFD blue - primary text
    public let foregroundSecondary = Color.hex(0x0088CC)  // Medium blue - secondary text
    public let foregroundTertiary = Color.hex(0x006699)  // Dim blue - tertiary/muted text

    // Accent colors
    public let accent = Color.hex(0x33BBFF)  // Lighter blue for highlights
    public let accentSecondary = Color.hex(0x0099DD)  // Darker accent

    // Semantic colors (stay in blue family)
    public let success = Color.hex(0x33CCFF)  // Cyan-blue
    public let warning = Color.hex(0x66CCFF)  // Light cyan
    public let error = Color.hex(0xFF6633)  // Orange-red (contrast)
    public let info = Color.hex(0x99DDFF)  // Pale blue

    // UI elements
    public let border = Color.hex(0x2D4A5A)  // Subtle blue border
    public let borderFocused = Color.hex(0x00AAFF)  // Bright when focused
    public let selection = Color.hex(0x33BBFF)  // Bright blue for selection text
    public let selectionBackground = Color.hex(0x1A3A4D)  // Dark blue for selection bar bg

    // Additional backgrounds
    public let statusBarBackground = Color.hex(0x0F1822)  // Dark blue for status bar
    public let appHeaderBackground = Color.hex(0x0A121C)  // Same as cap
    public let overlayBackground = Color.hex(0x060708)  // Dimming overlay
    public var buttonBackground: Color { Color.hex(0x14304A) }  // Lighter blue for buttons

    // Status bar
    public let statusBarForeground = Color.hex(0x0099EE)  // Slightly dimmer than primary foreground
    public let statusBarHighlight = Color.hex(0x33BBFF)

    public init() {}
}

// MARK: - Convenience Accessors

extension Palette where Self == BluePalette {
    /// Blue VFD terminal palette.
    public static var blue: BluePalette { BluePalette() }
}
