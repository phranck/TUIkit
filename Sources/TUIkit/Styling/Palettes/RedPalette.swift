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
/// All colors are generated algorithmically from a single base hue (0°)
/// using HSL transformations.
public struct RedPalette: BlockPalette {
    public let id = "red"
    public let name = "Red"

    /// The base hue used to generate all palette colors.
    private static let baseHue: Double = 0

    // Background
    public let background: Color

    // Red text hierarchy
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
        self.foreground = Color.hsl(hue, 100, 63)
        self.foregroundSecondary = Color.hsl(hue, 60, 50)
        self.foregroundTertiary = Color.hsl(hue, 62, 35)

        // Accent: lighter/brighter variant
        self.accent = Color.hsl(hue, 100, 70)

        // Semantic: hue-shifted from base
        self.success = Color.hsl(Self.wrapHue(hue + 30), 100, 75)
        self.warning = Color.hsl(Self.wrapHue(hue + 30), 100, 70)
        self.error = Color.hsl(0, 0, 100)
        self.info = Color.hsl(hue, 100, 80)

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

extension BlockPalette where Self == RedPalette {
    /// Red terminal palette.
    public static var red: RedPalette { RedPalette() }
}
