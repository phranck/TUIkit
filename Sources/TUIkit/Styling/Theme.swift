//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Theme.swift
//
//  Created by LAYERED.work
//  License: MIT  and palette registry.
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
/// paletteManager.setCurrent(SystemPalette(.amber))
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

    /// Background color for focused list/table rows.
    var focusBackground: Color { get }
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

    // MARK: - UI Element Defaults

    public var focusBackground: Color { foregroundTertiary.opacity(0.3) }
}

// MARK: - Palette Environment Key

/// Environment key for the current palette.
private struct PaletteKey: EnvironmentKey {
    static let defaultValue: any Palette = SystemPalette(.green)
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
     /// .environment(\.palette, SystemPalette(.green))
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
    /// All available palettes in cycling order, built from ``SystemPalette/Preset``.
    ///
    /// Order: Green → Amber → Red → Violet → Blue → White
    static let all: [any Palette] = SystemPalette.Preset.allCases.map { SystemPalette($0) }

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
    /// paletteManager.setCurrent(SystemPalette(.amber))
    /// ```
    public var paletteManager: ThemeManager {
        get { self[PaletteManagerKey.self] }
        set { self[PaletteManagerKey.self] = newValue }
    }
}
