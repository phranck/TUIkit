//  🖥️ TUIKit — Terminal UI Kit for Swift
//  GreenPalette.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

/// Classic green terminal palette (P1 phosphor).
///
/// Inspired by early CRT monitors like the IBM 5151 and Apple II.
/// All colors are generated algorithmically from a single base hue (120°)
/// using HSL transformations.
public struct GreenPalette: BlockPalette {
    public let id = "green"
    public let name = "Green"

    /// The base hue used to generate all palette colors.
    private static let baseHue: Double = 120

    // Background
    public let background: Color

    // Green text hierarchy
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
        self.foreground = Color.hsl(hue, 100, 60)
        self.foregroundSecondary = Color.hsl(hue, 67, 46)
        self.foregroundTertiary = Color.hsl(hue, 64, 34)

        // Accent: lighter/brighter variant
        self.accent = Color.hsl(hue, 100, 70)

        // Semantic: hue-shifted from base
        self.success = Color.hsl(hue, 100, 60)
        self.warning = Color.hsl(Self.wrapHue(hue - 45), 100, 60)
        self.error = Color.hsl(Self.wrapHue(hue - 105), 100, 60)
        self.info = Color.hsl(Self.wrapHue(hue + 45), 100, 60)

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

extension BlockPalette where Self == GreenPalette {
    /// The default palette (green).
    public static var `default`: GreenPalette { GreenPalette() }
    /// Green terminal palette.
    public static var green: GreenPalette { GreenPalette() }
}
