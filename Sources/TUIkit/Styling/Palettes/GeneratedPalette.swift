//
//  GeneratedPalette.swift
//  TUIkit
//
//  A palette that generates its entire color scheme from a single base hue.
//

/// A palette that generates its entire color scheme from a single base hue.
///
/// All colors are derived algorithmically using HSL transformations.
/// This allows creating new palettes with a single line of code.
///
/// # How it works
///
/// Given a base hue (0-360), the palette generates:
/// - **Backgrounds**: very low lightness, subtle saturation tinted toward the hue
/// - **Foregrounds**: high lightness with full saturation at the base hue
/// - **Accents**: slightly lighter/shifted versions of the foreground
/// - **Semantic colors**: hue-shifted variants (success = +120, warning = +60, error = +180, info = -60)
/// - **UI elements**: mid-range lightness/saturation for borders, selection, status bar
///
/// # Example
///
/// ```swift
/// // Create a violet palette
/// let violet = GeneratedPalette(name: "Violet", hue: 270)
///
/// // Create a teal palette
/// let teal = GeneratedPalette(name: "Teal", hue: 180)
/// ```
public struct GeneratedPalette: Palette, Sendable {
    public let id: String
    public let name: String

    // Background hierarchy
    public let background: Color
    public let backgroundSecondary: Color
    public let backgroundTertiary: Color

    // Foreground hierarchy
    public let foreground: Color
    public let foregroundSecondary: Color
    public let foregroundTertiary: Color

    // Accents
    public let accent: Color
    public let accentSecondary: Color

    // Semantic
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

    // Container (block appearance)
    public let containerBackground: Color
    public let containerHeaderBackground: Color
    public let buttonBackground: Color

    /// Creates a generated palette from a single base hue.
    ///
    /// - Parameters:
    ///   - name: The display name for the palette.
    ///   - hue: The base hue (0-360). Examples: red=0, green=120, blue=240, violet=270.
    ///   - saturation: The base saturation (0-100, default: 100). Lower values produce more muted palettes.
    public init(name: String, hue: Double, saturation: Double = 100) {
        self.id = "generated-\(name.lowercased())"
        self.name = name

        let baseSaturation = min(100, max(0, saturation))

        // --- Backgrounds: very dark, subtly tinted ---
        // App background — near black with a hint of the hue
        self.background = Color.hsl(hue, baseSaturation * 0.30, 3)
        // Container body — slightly brighter
        self.backgroundSecondary = Color.hsl(hue, baseSaturation * 0.40, 10)
        // Header/footer — between app and body
        self.backgroundTertiary = Color.hsl(hue, baseSaturation * 0.35, 7)

        // --- Foregrounds: bright, saturated text ---
        self.foreground = Color.hsl(hue, baseSaturation * 0.80, 70)
        self.foregroundSecondary = Color.hsl(hue, baseSaturation * 0.70, 55)
        self.foregroundTertiary = Color.hsl(hue, baseSaturation * 0.60, 40)

        // --- Accents: lighter/brighter variant ---
        self.accent = Color.hsl(hue, baseSaturation * 0.85, 78)
        self.accentSecondary = Color.hsl(hue, baseSaturation * 0.75, 50)

        // --- Semantic: hue-shifted from base ---
        // success = base + 120° (toward green family)
        let successHue = Self.wrapHue(hue + 120)
        self.success = Color.hsl(successHue, baseSaturation * 0.70, 65)

        // warning = base + 60° (toward yellow family)
        let warningHue = Self.wrapHue(hue + 60)
        self.warning = Color.hsl(warningHue, baseSaturation * 0.80, 70)

        // error = base + 180° (complementary)
        let errorHue = Self.wrapHue(hue + 180)
        self.error = Color.hsl(errorHue, baseSaturation * 0.85, 65)

        // info = base − 60° (analogous cool side)
        let infoHue = Self.wrapHue(hue - 60)
        self.info = Color.hsl(infoHue, baseSaturation * 0.70, 70)

        // --- UI elements ---
        self.border = Color.hsl(hue, baseSaturation * 0.40, 25)
        self.borderFocused = Color.hsl(hue, baseSaturation * 0.80, 70)
        self.selection = Color.hsl(hue, baseSaturation * 0.85, 78)
        self.selectionBackground = Color.hsl(hue, baseSaturation * 0.50, 18)

        // --- Status bar ---
        self.statusBarBackground = Color.hsl(hue, baseSaturation * 0.35, 8)
        self.statusBarForeground = Color.hsl(hue, baseSaturation * 0.75, 65)
        self.statusBarHighlight = Color.hsl(hue, baseSaturation * 0.85, 78)

        // --- Container (block appearance) ---
        self.containerBackground = Color.hsl(hue, baseSaturation * 0.40, 10)
        self.containerHeaderBackground = Color.hsl(hue, baseSaturation * 0.35, 7)
        self.buttonBackground = Color.hsl(hue, baseSaturation * 0.45, 15)
    }

    /// Wraps a hue value to the 0-360 range.
    private static func wrapHue(_ hue: Double) -> Double {
        var wrapped = hue.truncatingRemainder(dividingBy: 360)
        if wrapped < 0 { wrapped += 360 }
        return wrapped
    }

    // MARK: - Preset Hues

    /// Predefined hue values for common generated palettes.
    public enum Hue {
        /// Green hue (120°).
        public static let green: Double = 120
        /// Violet hue (270°).
        public static let violet: Double = 270
    }

    // MARK: - Presets

    /// A green generated palette — for direct comparison with GreenPalette.
    public static let green = Self(name: "Gen. Green", hue: Hue.green)
    /// A violet generated palette.
    public static let violet = Self(name: "Violet", hue: Hue.violet)
}

// MARK: - Convenience Accessors

extension Palette where Self == GeneratedPalette {
    /// Violet generated palette (hue 270°).
    public static var violet: GeneratedPalette { GeneratedPalette.violet }
}
