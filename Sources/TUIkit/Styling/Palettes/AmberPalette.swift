//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AmberPalette.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

/// Classic amber terminal palette (P3 phosphor).
///
/// Inspired by terminals like the IBM 3278 and Wyse 50.
/// All colors are generated algorithmically from a single base hue (40°)
/// using HSL transformations.
public struct AmberPalette: BlockPalette {
    public let id = "amber"
    public let name = "Amber"

    /// The base hue used to generate all palette colors.
    private static let baseHue: Double = 40

    // Background
    public let background: Color

    // Amber text hierarchy
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
        self.foregroundTertiary = Color.hsl(hue, 100, 28)

        // Accent: lighter/brighter variant
        self.accent = Color.hsl(hue + 5, 100, 60)

        // Semantic: hue-shifted from base
        self.success = Color.hsl(Self.wrapHue(hue + 40), 100, 60)
        self.warning = Color.hsl(Self.wrapHue(hue + 20), 100, 70)
        self.error = Color.hsl(Self.wrapHue(hue - 25), 100, 60)
        self.info = Color.hsl(Self.wrapHue(hue + 10), 100, 70)

        // UI elements
        self.border = Color.hsl(hue, 33, 26)

        // Additional backgrounds
        self.statusBarBackground = Color.hsl(hue, 35, 10)
        self.appHeaderBackground = Color.hsl(hue, 35, 7)
        self.overlayBackground = Color.hsl(hue, 30, 3)
    }

}

// MARK: - Private Helpers

private extension AmberPalette {
    /// Wraps a hue value to the 0–360 range.
    static func wrapHue(_ hue: Double) -> Double {
        var wrapped = hue.truncatingRemainder(dividingBy: 360)
        if wrapped < 0 { wrapped += 360 }
        return wrapped
    }
}

// MARK: - Convenience Accessors

extension BlockPalette where Self == AmberPalette {
    /// Amber terminal palette.
    public static var amber: AmberPalette { AmberPalette() }
}
