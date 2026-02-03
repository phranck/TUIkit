//
//  WhitePalette.swift
//  TUIkit
//
//  Classic white terminal palette (P4 phosphor).
//

/// Classic white terminal palette (P4 phosphor).
///
/// Inspired by terminals like the DEC VT100 and VT220.
/// Near-achromatic palette with a subtle cool blue tint (225°) in
/// backgrounds. Foregrounds are neutral gray. All colors are generated
/// algorithmically using HSL transformations.
public struct WhitePalette: BlockPalette {
    public let id = "white"
    public let name = "White"

    /// The base hue used for the subtle cool tint in backgrounds.
    private static let baseHue: Double = 225

    // Background
    public let background: Color

    // White/gray text hierarchy
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

        // Background: very dark, subtle cool tint
        self.background = Color.hsl(hue, 25, 3)

        // Foregrounds: near-neutral gray (very low saturation)
        self.foreground = Color.hsl(0, 0, 91)
        self.foregroundSecondary = Color.hsl(0, 0, 69)
        self.foregroundTertiary = Color.hsl(0, 0, 47)

        // Accent: pure white
        self.accent = Color.hsl(0, 0, 100)

        // Semantic colors: subtle tints on neutral base
        self.success = Color.hsl(120, 50, 75)
        self.warning = Color.hsl(40, 60, 75)
        self.error = Color.hsl(0, 60, 75)
        self.info = Color.hsl(210, 60, 75)

        // UI elements: neutral gray
        self.border = Color.hsl(0, 0, 28)

        // Additional backgrounds: subtle cool tint
        self.statusBarBackground = Color.hsl(hue, 20, 10)
        self.appHeaderBackground = Color.hsl(hue, 20, 7)
        self.overlayBackground = Color.hsl(hue, 25, 3)
    }
}

// MARK: - Convenience Accessors

extension BlockPalette where Self == WhitePalette {
    /// White terminal palette.
    public static var white: WhitePalette { WhitePalette() }
}
