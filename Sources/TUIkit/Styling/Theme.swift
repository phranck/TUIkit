//
//  Theme.swift
//  TUIkit
//
//  Palette protocol, default implementations, environment integration,
//  and palette registry.
//

import Foundation

// MARK: - Palette Protocol

/// A palette defines the color scheme for a TUIkit application.
///
/// Palettes provide semantic colors that views use for consistent styling.
/// TUIkit includes several predefined palettes inspired by classic terminals.
///
/// Conforms to ``Cyclable`` so it can be managed by a ``ThemeManager``.
///
/// # Usage
///
/// ```swift
/// // Set the app palette
/// paletteManager.setCurrent(AmberPalette())
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
    static let defaultValue: any Palette = GreenPalette()
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
     /// .environment(\.palette, GreenPalette())
    /// ```
    ///
    /// Access the palette in `renderToBuffer(context:)`:
    ///
    /// ```swift
    /// let palette = context.environment.palette
    /// let fg = palette.foreground
    /// ```
    public var palette: any Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

// MARK: - Palette Registry

/// Registry of available palettes.
public struct PaletteRegistry {
    /// All available palettes in cycling order.
    ///
    /// Order: Green → Gen. Green → Amber → White → Red → NCurses → Violet (generated)
    public static let all: [any Palette] = [
        GreenPalette(),
        GeneratedPalette.green,
        AmberPalette(),
        WhitePalette(),
        RedPalette(),
        NCursesPalette(),
        GeneratedPalette.violet,
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

// MARK: - PaletteManager Environment Key

/// Environment key for the palette manager.
private struct PaletteManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager(items: PaletteRegistry.all)
}

extension EnvironmentValues {
    /// The palette manager for cycling and setting palettes.
    ///
    /// ```swift
    /// let paletteManager = context.environment.paletteManager
    /// paletteManager.cycleNext()
    /// paletteManager.setCurrent(AmberPalette())
    /// ```
    public var paletteManager: ThemeManager {
        get { self[PaletteManagerKey.self] }
        set { self[PaletteManagerKey.self] = newValue }
    }
}
