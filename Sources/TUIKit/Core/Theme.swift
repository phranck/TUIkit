//
//  Theme.swift
//  TUIKit
//
//  Palette system with full 16M color support and predefined terminal palettes.
//

import Foundation

// MARK: - Palette Protocol

/// A palette defines the color scheme for a TUIKit application.
///
/// Palettes provide semantic colors that views use for consistent styling.
/// TUIKit includes several predefined palettes inspired by classic terminals.
///
/// Conforms to ``Cyclable`` so it can be managed by a ``ThemeManager``.
///
/// # Usage
///
/// ```swift
/// // Set the app palette
/// paletteManager.setCurrent(AmberPhosphorPalette())
///
/// // Use palette colors in views
/// Text("Hello").foregroundColor(.palette.foreground)
/// ```
public protocol Palette: Cyclable {
    // MARK: - Background Colors

    /// The primary background color.
    var background: Color { get }

    /// Secondary background for cards, panels, etc.
    var backgroundSecondary: Color { get }

    /// Tertiary background for nested elements.
    var backgroundTertiary: Color { get }

    // MARK: - Foreground Colors

    /// Primary text/foreground color.
    var foreground: Color { get }

    /// Secondary text color (less prominent).
    var foregroundSecondary: Color { get }

    /// Tertiary text color (even less prominent).
    var foregroundTertiary: Color { get }

    // MARK: - Accent Colors

    /// Primary accent color for interactive elements.
    var accent: Color { get }

    /// Secondary accent color.
    var accentSecondary: Color { get }

    // MARK: - Semantic Colors

    /// Color for success states.
    var success: Color { get }

    /// Color for warning states.
    var warning: Color { get }

    /// Color for error states.
    var error: Color { get }

    /// Color for informational states.
    var info: Color { get }

    // MARK: - UI Element Colors

    /// Border color for boxes, cards, etc.
    var border: Color { get }

    /// Border color for focused elements.
    var borderFocused: Color { get }

    /// Separator/divider color.
    var separator: Color { get }

    /// Selection highlight color (foreground).
    var selection: Color { get }

    /// Selection background color (dimmed accent).
    var selectionBackground: Color { get }

    /// Color for disabled elements.
    var disabled: Color { get }

    // MARK: - Status Bar Colors

    /// Status bar background.
    var statusBarBackground: Color { get }

    /// Status bar text color.
    var statusBarForeground: Color { get }

    /// Status bar shortcut highlight color.
    var statusBarHighlight: Color { get }

    // MARK: - Container Colors (for block appearance)

    /// Container body background (used in block appearance).
    var containerBackground: Color { get }

    /// Container header/footer background (darker than body, used in block appearance).
    var containerHeaderBackground: Color { get }

    /// Button background in block appearance (lighter than container body).
    var buttonBackground: Color { get }
}

// MARK: - Default Palette Implementation

extension Palette {
    // Default implementations using the primary colors

    public var backgroundSecondary: Color { background }
    public var backgroundTertiary: Color { background }
    public var foregroundSecondary: Color { foreground }
    public var foregroundTertiary: Color { foreground }
    public var accentSecondary: Color { accent }
    public var borderFocused: Color { accent }
    public var separator: Color { border }
    public var selection: Color { accent }
    public var selectionBackground: Color { backgroundSecondary }
    public var disabled: Color { foregroundTertiary }
    public var statusBarBackground: Color { backgroundSecondary }
    public var statusBarForeground: Color { foreground }
    public var statusBarHighlight: Color { accent }
    public var containerBackground: Color { backgroundSecondary }
    public var containerHeaderBackground: Color { backgroundTertiary }
    public var buttonBackground: Color { backgroundSecondary }
}

// MARK: - Palette Environment Key

/// Environment key for the current palette.
private struct PaletteKey: EnvironmentKey {
    static let defaultValue: any Palette = GreenPhosphorPalette()
}

extension EnvironmentValues {
    /// The current palette.
    ///
    /// Set a palette at the app level and it propagates to all child views:
    ///
    /// ```swift
    /// WindowGroup {
    ///     ContentView()
    /// }
    /// .environment(\.palette, GreenPhosphorPalette())
    /// ```
    ///
    /// Access the palette in views:
    ///
    /// ```swift
    /// struct MyView: View {
    ///     @Environment(\.palette) var palette
    ///
    ///     var body: some View {
    ///         Text("Hello")
    ///             .foregroundColor(palette.foreground)
    ///     }
    /// }
    /// ```
    public var palette: any Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

// MARK: - Color Palette Extension

extension Color {
    /// Access palette colors from the current environment.
    ///
    /// These colors read from `EnvironmentStorage.shared` during rendering.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Hello").foregroundColor(.palette.foreground)
    /// ```
    public static var palette: PaletteColors.Type {
        PaletteColors.self
    }

    /// Legacy accessor kept for source compatibility.
    ///
    /// Prefer `.palette` for new code.
    public static var theme: PaletteColors.Type {
        PaletteColors.self
    }
}

/// Namespace for palette-aware colors.
///
/// These properties read the current palette from the environment storage
/// that is set during rendering.
public enum PaletteColors {
    /// Gets the current palette from environment storage.
    private static var current: any Palette {
        EnvironmentStorage.shared.environment.palette
    }

    /// Primary background color.
    public static var background: Color { current.background }

    /// Secondary background color.
    public static var backgroundSecondary: Color { current.backgroundSecondary }

    /// Tertiary background color.
    public static var backgroundTertiary: Color { current.backgroundTertiary }

    /// Primary foreground color.
    public static var foreground: Color { current.foreground }

    /// Secondary foreground color.
    public static var foregroundSecondary: Color { current.foregroundSecondary }

    /// Tertiary foreground color.
    public static var foregroundTertiary: Color { current.foregroundTertiary }

    /// Primary accent color.
    public static var accent: Color { current.accent }

    /// Secondary accent color.
    public static var accentSecondary: Color { current.accentSecondary }

    /// Success color.
    public static var success: Color { current.success }

    /// Warning color.
    public static var warning: Color { current.warning }

    /// Error color.
    public static var error: Color { current.error }

    /// Info color.
    public static var info: Color { current.info }

    /// Border color.
    public static var border: Color { current.border }

    /// Focused border color.
    public static var borderFocused: Color { current.borderFocused }

    /// Separator color.
    public static var separator: Color { current.separator }

    /// Selection color.
    public static var selection: Color { current.selection }

    /// Selection background color.
    public static var selectionBackground: Color { current.selectionBackground }

    /// Disabled color.
    public static var disabled: Color { current.disabled }

    /// Status bar background.
    public static var statusBarBackground: Color { current.statusBarBackground }

    /// Status bar foreground.
    public static var statusBarForeground: Color { current.statusBarForeground }

    /// Status bar highlight.
    public static var statusBarHighlight: Color { current.statusBarHighlight }

    /// Container body background (for block appearance).
    public static var containerBackground: Color { current.containerBackground }

    /// Container header/footer background (for block appearance).
    public static var containerHeaderBackground: Color { current.containerHeaderBackground }
}

// MARK: - Predefined Palettes

/// Classic green phosphor terminal palette (P1 phosphor).
///
/// Inspired by early CRT monitors like the IBM 5151 and Apple II.
/// Uses a dark background with subtle green tint.
public struct GreenPhosphorPalette: Palette {
    public let id = "green-phosphor"
    public let name = "Green"

    // Background hierarchy
    public let background = Color.hex(0x060A07)             // App background (darkest)
    public let backgroundSecondary = Color.hex(0x0E271C)    // Container body background (brighter)
    public let backgroundTertiary = Color.hex(0x0A1B13)     // Header/footer background

    // Green phosphor text hierarchy
    public let foreground = Color.hex(0x33FF33)           // Bright green - primary text
    public let foregroundSecondary = Color.hex(0x27C227)  // Medium green - secondary text
    public let foregroundTertiary = Color.hex(0x1F8F1F)   // Dim green - tertiary/muted text

    // Accent colors
    public let accent = Color.hex(0x66FF66)               // Lighter green for highlights
    public let accentSecondary = Color.hex(0x00CC00)      // Darker accent

    // Semantic colors (stay in green family)
    public let success = Color.hex(0x33FF33)
    public let warning = Color.hex(0xCCFF33)              // Yellow-green
    public let error = Color.hex(0xFF6633)                // Orange-red (contrast)
    public let info = Color.hex(0x33FFCC)                 // Cyan-green

    // UI elements
    public let border = Color.hex(0x2D5A2D)               // Subtle green border
    public let borderFocused = Color.hex(0x33FF33)        // Bright when focused
    public let selection = Color.hex(0x66FF66)            // Bright green for selection text
    public let selectionBackground = Color.hex(0x1A4D1A)  // Dark green for selection bar bg

    // Status bar
    public let statusBarBackground = Color.hex(0x0F2215)  // Dark green for status bar
    public let statusBarForeground = Color.hex(0x2FDD2F)  // Slightly dimmer than primary foreground
    public let statusBarHighlight = Color.hex(0x66FF66)

    // Container colors for block appearance
    public var containerBackground: Color { backgroundSecondary }       // #0E271C - body
    public var containerHeaderBackground: Color { backgroundTertiary }  // #0A1B13 - header/footer
    public var buttonBackground: Color { Color.hex(0x145523) }          // Lighter green for buttons

    public init() {}
}

/// Classic amber phosphor terminal palette (P3 phosphor).
///
/// Inspired by terminals like the IBM 3278 and Wyse 50.
/// Uses a dark background with subtle amber/orange tint.
public struct AmberPhosphorPalette: Palette {
    public let id = "amber-phosphor"
    public let name = "Amber"

    // Background hierarchy
    public let background = Color.hex(0x0A0706)             // App background (darkest)
    public let backgroundSecondary = Color.hex(0x251710)    // Container body background (brighter)
    public let backgroundTertiary = Color.hex(0x1E110E)     // Header/footer background

    // Amber phosphor text hierarchy (matching Spotnik)
    public let foreground = Color.hex(0xFFAA00)           // Bright amber - primary text
    public let foregroundSecondary = Color.hex(0xCC8800)  // Medium amber - secondary text
    public let foregroundTertiary = Color.hex(0x8F6600)   // Dim amber - tertiary/muted text

    // Accent colors
    public let accent = Color.hex(0xFFCC33)               // Lighter amber for highlights
    public let accentSecondary = Color.hex(0xCC9900)      // Darker accent

    // Semantic colors (stay in amber family)
    public let success = Color.hex(0xFFCC00)
    public let warning = Color.hex(0xFFE066)              // Light amber
    public let error = Color.hex(0xFF6633)                // Orange-red (contrast)
    public let info = Color.hex(0xFFD966)                 // Light amber

    // UI elements
    public let border = Color.hex(0x5A4A2D)               // Subtle amber border
    public let borderFocused = Color.hex(0xFFAA00)        // Bright when focused
    public let selection = Color.hex(0xFFCC33)            // Bright amber for selection text
    public let selectionBackground = Color.hex(0x4D3A1F)  // Dark amber for selection bar bg

    // Status bar
    public let statusBarBackground = Color.hex(0x191613)  // Same as header/footer
    public let statusBarForeground = Color.hex(0xFFAA00)
    public let statusBarHighlight = Color.hex(0xFFCC33)

    // Container colors for block appearance
    public var containerBackground: Color { backgroundSecondary }       // Body
    public var containerHeaderBackground: Color { backgroundTertiary }  // Header/footer
    public var buttonBackground: Color { Color.hex(0x3A2A1D) }          // Lighter amber for buttons

    public init() {}
}

/// Classic white phosphor terminal palette (P4 phosphor).
///
/// Inspired by terminals like the DEC VT100 and VT220.
/// Uses a dark background with subtle cool/blue tint.
public struct WhitePhosphorPalette: Palette {
    public let id = "white-phosphor"
    public let name = "White"

    // Background hierarchy
    public let background = Color.hex(0x06070A)             // App background (darkest)
    public let backgroundSecondary = Color.hex(0x111A2A)    // Container body background (brighter)
    public let backgroundTertiary = Color.hex(0x0D131D)     // Header/footer background

    // White/gray phosphor text hierarchy
    public let foreground = Color.hex(0xE8E8E8)           // Bright white - primary text
    public let foregroundSecondary = Color.hex(0xB0B0B0)  // Medium gray - secondary text
    public let foregroundTertiary = Color.hex(0x787878)   // Dim gray - tertiary/muted text

    // Accent colors
    public let accent = Color.hex(0xFFFFFF)               // Pure white for highlights
    public let accentSecondary = Color.hex(0xC0C0C0)      // Light gray accent

    // Semantic colors (subtle tints)
    public let success = Color.hex(0xC0FFC0)              // Slight green tint
    public let warning = Color.hex(0xFFE0A0)              // Slight amber tint
    public let error = Color.hex(0xFFA0A0)                // Slight red tint
    public let info = Color.hex(0xA0D0FF)                 // Slight blue tint

    // UI elements
    public let border = Color.hex(0x484848)               // Subtle gray border
    public let borderFocused = Color.hex(0xE8E8E8)        // Bright when focused
    public let selection = Color.hex(0xFFFFFF)            // White for selection text
    public let selectionBackground = Color.hex(0x3A3A3A)  // Dark gray for selection bar bg

    // Status bar
    public let statusBarBackground = Color.hex(0x131619)  // Same as header/footer
    public let statusBarForeground = Color.hex(0xDCDCDC)  // Slightly dimmer than primary foreground
    public let statusBarHighlight = Color.hex(0xFFFFFF)

    // Container colors for block appearance
    public var containerBackground: Color { backgroundSecondary }       // Body
    public var containerHeaderBackground: Color { backgroundTertiary }  // Header/footer
    public var buttonBackground: Color { Color.hex(0x1D2535) }          // Lighter gray for buttons

    public init() {}
}

/// Red phosphor terminal palette.
///
/// Less common but used in some military and specialized applications.
/// Night-vision friendly with reduced eye strain in dark environments.
public struct RedPhosphorPalette: Palette {
    public let id = "red-phosphor"
    public let name = "Red"

    // Background hierarchy
    public let background = Color.hex(0x0A0606)             // App background (darkest)
    public let backgroundSecondary = Color.hex(0x281112)    // Container body background (brighter)
    public let backgroundTertiary = Color.hex(0x1E0F10)     // Header/footer background

    // Red phosphor text hierarchy
    public let foreground = Color.hex(0xFF4444)           // Bright red - primary text
    public let foregroundSecondary = Color.hex(0xCC3333)  // Medium red - secondary text
    public let foregroundTertiary = Color.hex(0x8F2222)   // Dim red - tertiary/muted text

    // Accent colors
    public let accent = Color.hex(0xFF6666)               // Lighter red for highlights
    public let accentSecondary = Color.hex(0xCC4444)      // Darker accent

    // Semantic colors (stay in red family)
    public let success = Color.hex(0xFF8080)              // Light red (success in red theme)
    public let warning = Color.hex(0xFFAA66)              // Orange
    public let error = Color.hex(0xFFFFFF)                // White (stands out as error)
    public let info = Color.hex(0xFF9999)                 // Light red

    // UI elements
    public let border = Color.hex(0x5A2D2D)               // Subtle red border
    public let borderFocused = Color.hex(0xFF4444)        // Bright when focused
    public let selection = Color.hex(0xFF6666)            // Bright red for selection text
    public let selectionBackground = Color.hex(0x4D1F1F)  // Dark red for selection bar bg

    // Status bar
    public let statusBarBackground = Color.hex(0x191313)  // Same as header/footer
    public let statusBarForeground = Color.hex(0xF23B3B)  // Slightly dimmer than primary foreground
    public let statusBarHighlight = Color.hex(0xFF6666)

    // Container colors for block appearance
    public var containerBackground: Color { backgroundSecondary }       // Body
    public var containerHeaderBackground: Color { backgroundTertiary }  // Header/footer
    public var buttonBackground: Color { Color.hex(0x3A1F22) }          // Lighter red for buttons

    public init() {}
}

/// Classic ncurses-style palette.
///
/// Traditional terminal colors as used in ncurses applications
/// like htop, mc (Midnight Commander), and vim.
public struct NCursesPalette: Palette {
    public let id = "ncurses"
    public let name = "ncurses"

    // Standard terminal black background
    public let background = Color.black
    public let backgroundSecondary = Color.blue
    public let backgroundTertiary = Color.brightBlack
    public let foreground = Color.white
    public let foregroundSecondary = Color.brightWhite
    public let foregroundTertiary = Color.brightBlack
    public let accent = Color.cyan
    public let accentSecondary = Color.brightCyan
    public let success = Color.green
    public let warning = Color.yellow
    public let error = Color.red
    public let info = Color.cyan
    public let border = Color.white
    public let borderFocused = Color.brightCyan
    public let selection = Color.brightCyan
    public let selectionBackground = Color.blue
    public let disabled = Color.brightBlack
    public let statusBarBackground = Color.blue
    public let statusBarForeground = Color.white
    public let statusBarHighlight = Color.yellow

    public var containerBackground: Color { backgroundSecondary }
    public var containerHeaderBackground: Color { backgroundTertiary }
    public var buttonBackground: Color { Color.brightBlue }

    public init() {}
}

// MARK: - Generated Palette

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

    /// A green generated palette — for direct comparison with GreenPhosphorPalette.
    public static let green = Self(name: "Gen. Green", hue: Hue.green)
    /// A violet generated palette.
    public static let violet = Self(name: "Violet", hue: Hue.violet)
}

// MARK: - Palette Registry

/// Registry of available palettes.
public struct PaletteRegistry {
    /// All available palettes in cycling order.
    ///
    /// Order: Green → Gen. Green → Amber → White → Red → NCurses → Violet (generated)
    public static let all: [any Palette] = [
        GreenPhosphorPalette(),
        GeneratedPalette.green,
        AmberPhosphorPalette(),
        WhitePhosphorPalette(),
        RedPhosphorPalette(),
        NCursesPalette(),
        GeneratedPalette.violet
    ]

    /// Finds a palette by ID.
    public static func palette(withId id: String) -> (any Palette)? {
        all.first { $0.id == id }
    }

    /// Finds a palette by name.
    public static func palette(withName name: String) -> (any Palette)? {
        all.first { $0.name == name }
    }
}

// MARK: - Convenience Palette Accessors

extension Palette where Self == GreenPhosphorPalette {
    /// The default palette (green phosphor).
    public static var `default`: GreenPhosphorPalette { GreenPhosphorPalette() }
    /// Green phosphor terminal palette.
    public static var green: GreenPhosphorPalette { GreenPhosphorPalette() }
    /// Green phosphor terminal palette (alias).
    public static var greenPhosphor: GreenPhosphorPalette { GreenPhosphorPalette() }
}

extension Palette where Self == AmberPhosphorPalette {
    /// Amber phosphor terminal palette.
    public static var amber: AmberPhosphorPalette { AmberPhosphorPalette() }
    /// Amber phosphor terminal palette (alias).
    public static var amberPhosphor: AmberPhosphorPalette { AmberPhosphorPalette() }
}

extension Palette where Self == WhitePhosphorPalette {
    /// White phosphor terminal palette.
    public static var white: WhitePhosphorPalette { WhitePhosphorPalette() }
    /// White phosphor terminal palette (alias).
    public static var whitePhosphor: WhitePhosphorPalette { WhitePhosphorPalette() }
}

extension Palette where Self == RedPhosphorPalette {
    /// Red phosphor terminal palette.
    public static var red: RedPhosphorPalette { RedPhosphorPalette() }
    /// Red phosphor terminal palette (alias).
    public static var redPhosphor: RedPhosphorPalette { RedPhosphorPalette() }
}

extension Palette where Self == NCursesPalette {
    /// Classic ncurses palette.
    public static var ncurses: NCursesPalette { NCursesPalette() }
}

extension Palette where Self == GeneratedPalette {
    /// Violet generated palette (hue 270°).
    public static var violet: GeneratedPalette { GeneratedPalette.violet }
}

// MARK: - PaletteManager Environment Key

/// Environment key for the palette manager.
private struct PaletteManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager(
        items: PaletteRegistry.all,
        applyToEnvironment: { item in
            if let palette = item as? any Palette {
                EnvironmentStorage.shared.environment.palette = palette
            }
        }
    )
}

extension EnvironmentValues {
    /// The palette manager for cycling and setting palettes.
    ///
    /// ```swift
    /// @Environment(\.paletteManager) var paletteManager
    ///
    /// paletteManager.cycleNext()
    /// paletteManager.setCurrent(AmberPhosphorPalette())
    /// ```
    public var paletteManager: ThemeManager {
        get { self[PaletteManagerKey.self] }
        set { self[PaletteManagerKey.self] = newValue }
    }
}
