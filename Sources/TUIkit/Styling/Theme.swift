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

    /// The app background color (darkest).
    var background: Color { get }

    /// Container body/content background.
    var containerBodyBackground: Color { get }

    /// Container header/footer background (the "cap" of a container).
    var containerCapBackground: Color { get }

    /// Button background (slightly lighter than containerCapBackground).
    var buttonBackground: Color { get }

    /// Status bar background.
    var statusBarBackground: Color { get }

    /// App header background (for future use).
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

    /// Placeholder text color (weakest foreground, e.g. for empty input fields).
    var foregroundPlaceholder: Color { get }

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

    /// Status bar text color.
    var statusBarForeground: Color { get }

    /// Status bar shortcut highlight color.
    var statusBarHighlight: Color { get }
}

// MARK: - Default Palette Implementation

extension Palette {
    // MARK: - Background Defaults

    public var containerBodyBackground: Color { background }
    public var containerCapBackground: Color { background }
    public var buttonBackground: Color { containerCapBackground }
    public var statusBarBackground: Color { background }
    public var appHeaderBackground: Color { containerCapBackground }
    public var overlayBackground: Color { background }

    // MARK: - Foreground Defaults

    public var foregroundSecondary: Color { foreground }
    public var foregroundTertiary: Color { foreground }
    public var foregroundPlaceholder: Color { foregroundTertiary }

    // MARK: - Accent Defaults

    public var accentSecondary: Color { accent }

    // MARK: - UI Element Defaults (derived from essentials)

    public var borderFocused: Color { accent }
    public var separator: Color { border }
    public var selection: Color { accent }
    public var selectionBackground: Color { containerBodyBackground }
    public var disabled: Color { foregroundTertiary }

    // MARK: - Status Bar Defaults

    public var statusBarForeground: Color { foreground }
    public var statusBarHighlight: Color { accent }
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
    /// Order: Green → Amber → Red → Violet → Blue → White → NCurses
    static let all: [any Palette] = [
        GreenPalette(),
        AmberPalette(),
        RedPalette(),
        VioletPalette(),
        BluePalette(),
        WhitePalette(),
        NCursesPalette(),
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
