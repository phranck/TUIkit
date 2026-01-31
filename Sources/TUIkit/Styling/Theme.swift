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
/// For block-appearance-specific backgrounds (surfaces, elevated elements),
/// see ``BlockPalette``.
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

    /// The app background color (darkest).
    var background: Color { get }

    /// Status bar background.
    var statusBarBackground: Color { get }

    /// App header background.
    var appHeaderBackground: Color { get }

    /// Dimming overlay background for alerts and dialogs.
    var overlayBackground: Color { get }

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
}

// MARK: - Default Palette Implementation

extension Palette {
    // MARK: - Background Defaults

    public var statusBarBackground: Color { background }
    public var appHeaderBackground: Color { background }
    public var overlayBackground: Color { background }

    // MARK: - Foreground Defaults

    public var foregroundSecondary: Color { foreground }
    public var foregroundTertiary: Color { foreground }
}

// MARK: - BlockPalette Protocol

/// A palette with additional background colors for block-style appearances.
///
/// Block appearances use solid background fills to visually separate containers,
/// headers, and interactive elements. `BlockPalette` extends ``Palette`` with
/// three surface-level backgrounds that create this visual hierarchy.
///
/// All three properties provide computed defaults based on ``Palette/background``
/// using ``Color/lighter(by:)``, so conforming types don't need to define them
/// explicitly unless custom values are desired.
///
/// # Default Hierarchy
///
/// ```
/// background                          (darkest)
/// └── surfaceHeaderBackground         (background.lighter(by: 0.05))
///     └── surfaceBackground           (background.lighter(by: 0.08))
///         └── elevatedBackground      (surfaceHeaderBackground.lighter(by: 0.05))
/// ```
public protocol BlockPalette: Palette {
    /// Container body/content background.
    ///
    /// Used for the main content area of containers, menus, and bordered regions
    /// in block appearance mode.
    var surfaceBackground: Color { get }

    /// Container header/footer background.
    ///
    /// Used for the "cap" area of containers (title bars, footers) and menu
    /// headers in block appearance mode.
    var surfaceHeaderBackground: Color { get }

    /// Elevated element background (buttons, interactive surfaces).
    ///
    /// Used for elements that sit visually "above" the surface, such as
    /// buttons in block appearance mode.
    var elevatedBackground: Color { get }
}

// MARK: - Default BlockPalette Implementation

extension BlockPalette {
    public var surfaceBackground: Color { background.lighter(by: 0.08) }
    public var surfaceHeaderBackground: Color { background.lighter(by: 0.05) }
    public var elevatedBackground: Color { surfaceHeaderBackground.lighter(by: 0.05) }
}

// MARK: - BlockPalette Convenience Accessors

extension Palette {
    /// The surface background if this palette is a ``BlockPalette``, otherwise ``background``.
    var blockSurfaceBackground: Color {
        (self as? any BlockPalette)?.surfaceBackground ?? background
    }

    /// The surface header background if this palette is a ``BlockPalette``, otherwise ``background``.
    var blockSurfaceHeaderBackground: Color {
        (self as? any BlockPalette)?.surfaceHeaderBackground ?? background
    }

    /// The elevated background if this palette is a ``BlockPalette``, otherwise ``background``.
    var blockElevatedBackground: Color {
        (self as? any BlockPalette)?.elevatedBackground ?? background
    }
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
struct PaletteRegistry {
    /// All available palettes in cycling order.
    ///
    /// Order: Green → Amber → Red → Violet → Blue → White
    static let all: [any Palette] = [
        GreenPalette(),
        AmberPalette(),
        RedPalette(),
        VioletPalette(),
        BluePalette(),
        WhitePalette(),
    ]

    /// Finds a palette by ID.
    static func palette(withId id: String) -> (any Palette)? {
        all.first { $0.id == id }
    }

    /// Finds a palette by name.
    static func palette(withName name: String) -> (any Palette)? {
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
