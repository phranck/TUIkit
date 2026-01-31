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
public struct BluePalette: BlockPalette {
    public let id = "blue"
    public let name = "Blue"

    // Background
    public let background = Color.hex(0x060708)

    // Blue text hierarchy
    public let foreground = Color.hex(0x00AAFF)  // Bright VFD blue - primary text
    public let foregroundSecondary = Color.hex(0x0088CC)  // Medium blue - secondary text
    public let foregroundTertiary = Color.hex(0x006699)  // Dim blue - tertiary/muted text

    // Accent
    public let accent = Color.hex(0x33BBFF)  // Lighter blue for highlights

    // Semantic colors (stay in blue family)
    public let success = Color.hex(0x33CCFF)  // Cyan-blue
    public let warning = Color.hex(0x66CCFF)  // Light cyan
    public let error = Color.hex(0xFF6633)  // Orange-red (contrast)
    public let info = Color.hex(0x99DDFF)  // Pale blue

    // UI elements
    public let border = Color.hex(0x2D4A5A)  // Subtle blue border

    // Additional backgrounds
    public let statusBarBackground = Color.hex(0x0F1822)
    public let appHeaderBackground = Color.hex(0x0A121C)
    public let overlayBackground = Color.hex(0x060708)

    public init() {}
}

// MARK: - Convenience Accessors

extension BlockPalette where Self == BluePalette {
    /// Blue VFD terminal palette.
    public static var blue: BluePalette { BluePalette() }
}
