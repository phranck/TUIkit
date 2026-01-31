//  VioletPalette.swift
//  TUIkit — Terminal UI Framework for Swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

/// Violet terminal palette.
///
/// Inspired by retro computing aesthetics and sci-fi terminal displays.
/// All colors are generated algorithmically from a single base hue (270°)
/// using HSL transformations.
public struct VioletPalette: Palette {
    public let id = "violet"
    public let name = "Violet"

    /// The base hue used to generate all palette colors.
    private static let baseHue: Double = 270

    // Background hierarchy
    public let background: Color
    public let backgroundSecondary: Color
    public let backgroundTertiary: Color

    // Violet text hierarchy
    public let foreground: Color
    public let foregroundSecondary: Color
    public let foregroundTertiary: Color

    // Accent colors
    public let accent: Color
    public let accentSecondary: Color

    // Semantic colors
    public let success: Color
    public let warning: Color
    public let error: Color
    public let info: Color

    // UI elements
    public let border: Color
    public let borderFocused: Color
    public let selection: Color
    public let selectionBackground: Color

    // Status bar
    public let statusBarBackground: Color
    public let statusBarForeground: Color
    public let statusBarHighlight: Color

    // Container colors for block appearance
    public let containerBackground: Color
    public let containerHeaderBackground: Color
    public let buttonBackground: Color

    public init() {
        let hue = Self.baseHue

        // Backgrounds: very dark, subtly tinted
        self.background = Color.hsl(hue, 30, 3)
        self.backgroundSecondary = Color.hsl(hue, 40, 10)
        self.backgroundTertiary = Color.hsl(hue, 35, 7)

        // Foregrounds: bright, saturated text
        self.foreground = Color.hsl(hue, 80, 70)
        self.foregroundSecondary = Color.hsl(hue, 70, 55)
        self.foregroundTertiary = Color.hsl(hue, 60, 40)

        // Accents: lighter/brighter variant
        self.accent = Color.hsl(hue, 85, 78)
        self.accentSecondary = Color.hsl(hue, 75, 50)

        // Semantic: hue-shifted from base
        self.success = Color.hsl(Self.wrapHue(hue + 120), 70, 65)
        self.warning = Color.hsl(Self.wrapHue(hue + 60), 80, 70)
        self.error = Color.hsl(Self.wrapHue(hue + 180), 85, 65)
        self.info = Color.hsl(Self.wrapHue(hue - 60), 70, 70)

        // UI elements
        self.border = Color.hsl(hue, 40, 25)
        self.borderFocused = Color.hsl(hue, 80, 70)
        self.selection = Color.hsl(hue, 85, 78)
        self.selectionBackground = Color.hsl(hue, 50, 18)

        // Status bar
        self.statusBarBackground = Color.hsl(hue, 35, 8)
        self.statusBarForeground = Color.hsl(hue, 75, 65)
        self.statusBarHighlight = Color.hsl(hue, 85, 78)

        // Container (block appearance)
        self.containerBackground = Color.hsl(hue, 40, 10)
        self.containerHeaderBackground = Color.hsl(hue, 35, 7)
        self.buttonBackground = Color.hsl(hue, 45, 15)
    }

    /// Wraps a hue value to the 0–360 range.
    private static func wrapHue(_ hue: Double) -> Double {
        var wrapped = hue.truncatingRemainder(dividingBy: 360)
        if wrapped < 0 { wrapped += 360 }
        return wrapped
    }
}

// MARK: - Convenience Accessors

extension Palette where Self == VioletPalette {
    /// Violet terminal palette.
    public static var violet: VioletPalette { VioletPalette() }
}
