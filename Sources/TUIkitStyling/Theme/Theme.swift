//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Theme.swift
//
//  Created by LAYERED.work
//  License: MIT  and palette registry.
//


// MARK: - Palette Protocol

/// A palette defines the color scheme for a TUIkit application.
///
/// Palettes provide semantic colors that views use for consistent styling.
/// TUIkit includes several predefined palettes inspired by classic terminals.
///
/// Conforms to ``Cyclable`` so it can be managed by a `ThemeManager`.
///
/// # Usage
///
/// ```swift
/// // Set the app palette
/// paletteManager.setCurrent(SystemPalette(.amber))
///
/// // Use palette colors in views
/// Text("Hello").foregroundStyle(.palette.foreground)
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

    /// Quaternary text color (dimmest foreground, used for subtle UI elements like spinner tracks).
    var foregroundQuaternary: Color { get }

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

    /// Background color for focused list/table rows.
    var focusBackground: Color { get }

    /// Text cursor color for TextField and SecureField.
    ///
    /// Defaults to `accent` if not explicitly set. Custom palettes can override
    /// this to provide a distinct cursor color independent of the accent.
    var cursorColor: Color { get }
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
    public var foregroundQuaternary: Color { foregroundTertiary }

    // MARK: - UI Element Defaults

    public var focusBackground: Color { foregroundTertiary.opacity(0.3) }

    public var cursorColor: Color { accent }
}

// MARK: - Palette Registry

/// Registry of available palettes.
public struct PaletteRegistry {
    /// All available palettes in cycling order, built from ``SystemPalette/Preset``.
    ///
    /// Order: Green → Amber → Red → Violet → Blue → White
    public static let all: [any Palette] = SystemPalette.Preset.allCases.map { SystemPalette($0) }

    /// Finds a palette by ID.
    public static func palette(withId id: String) -> (any Palette)? {
        all.first { $0.id == id }
    }

    /// Finds a palette by name.
    public static func palette(withName name: String) -> (any Palette)? {
        all.first { $0.name == name }
    }
}
