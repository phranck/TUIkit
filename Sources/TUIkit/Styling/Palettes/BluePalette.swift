//  BluePalette.swift
//  TUIkit — Terminal UI Framework for Swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

/// Blue VFD terminal palette.
///
/// Inspired by vintage vacuum fluorescent displays (VFDs) found in
/// audio equipment, cash registers, and instrument panels.
/// All colors are generated algorithmically from a single base hue (200°)
/// using HSL transformations.
public struct BluePalette: BlockPalette {
    public let id = "blue"
    public let name = "Blue"

    /// The base hue used to generate all palette colors.
    private static let baseHue: Double = 200

    // Background
    public let background: Color

    // Blue text hierarchy
    public let foreground: Color
    public let foregroundSecondary: Color
    public let foregroundTertiary: Color

    // Accent
    public let accent: Color

    // Semantic colors
    public let success: Color
    public let warning: Color
    public let error: Color
    public let info: Color

    // UI elements
    public let border: Color

    // Additional backgrounds
    public let statusBarBackground: Color
    public let appHeaderBackground: Color
    public let overlayBackground: Color

    public init() {
        let hue = Self.baseHue

        // Background: very dark, subtly tinted
        self.background = Color.hsl(hue, 30, 3)

        // Foregrounds: bright, saturated text
        self.foreground = Color.hsl(hue, 100, 50)
        self.foregroundSecondary = Color.hsl(hue, 100, 40)
        self.foregroundTertiary = Color.hsl(hue, 100, 30)

        // Accent: lighter/brighter variant
        self.accent = Color.hsl(hue, 100, 60)

        // Semantic: hue-shifted from base
        self.success = Color.hsl(Self.wrapHue(hue + 10), 100, 60)
        self.warning = Color.hsl(Self.wrapHue(hue + 20), 100, 70)
        self.error = Color.hsl(Self.wrapHue(hue - 185), 100, 60)
        self.info = Color.hsl(Self.wrapHue(hue + 5), 100, 75)

        // UI elements
        self.border = Color.hsl(hue, 33, 26)

        // Additional backgrounds
        self.statusBarBackground = Color.hsl(hue, 35, 10)
        self.appHeaderBackground = Color.hsl(hue, 35, 7)
        self.overlayBackground = Color.hsl(hue, 30, 3)
    }

    /// Wraps a hue value to the 0–360 range.
    private static func wrapHue(_ hue: Double) -> Double {
        var wrapped = hue.truncatingRemainder(dividingBy: 360)
        if wrapped < 0 { wrapped += 360 }
        return wrapped
    }
}

// MARK: - Convenience Accessors

extension BlockPalette where Self == BluePalette {
    /// Blue VFD terminal palette.
    public static var blue: BluePalette { BluePalette() }
}
