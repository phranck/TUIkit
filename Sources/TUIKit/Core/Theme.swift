//
//  Theme.swift
//  TUIKit
//
//  Theming system with full 16M color support and predefined terminal themes.
//

import Foundation

// MARK: - Theme Protocol

/// A theme defines the color palette for a TUIKit application.
///
/// Themes provide semantic colors that views use for consistent styling.
/// TUIKit includes several predefined themes inspired by classic terminals.
///
/// # Usage
///
/// ```swift
/// // Set the app theme
/// ThemeManager.shared.current = .amber
///
/// // Use theme colors in views
/// Text("Hello").foregroundColor(.theme.primary)
/// ```
public protocol Theme: Sendable {
    /// The theme's unique identifier.
    var id: String { get }

    /// The theme's display name.
    var name: String { get }

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

    /// Selection highlight color.
    var selection: Color { get }

    /// Color for disabled elements.
    var disabled: Color { get }

    // MARK: - Status Bar Colors

    /// Status bar background.
    var statusBarBackground: Color { get }

    /// Status bar text color.
    var statusBarForeground: Color { get }

    /// Status bar shortcut highlight color.
    var statusBarHighlight: Color { get }
}

// MARK: - Default Theme Implementation

extension Theme {
    // Default implementations using the primary colors

    public var backgroundSecondary: Color { background }
    public var backgroundTertiary: Color { background }
    public var foregroundSecondary: Color { foreground }
    public var foregroundTertiary: Color { foreground }
    public var accentSecondary: Color { accent }
    public var borderFocused: Color { accent }
    public var separator: Color { border }
    public var selection: Color { accent }
    public var disabled: Color { foregroundTertiary }
    public var statusBarBackground: Color { backgroundSecondary }
    public var statusBarForeground: Color { foreground }
    public var statusBarHighlight: Color { accent }
}

// MARK: - Theme Environment Key

/// Environment key for the current theme.
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = GreenPhosphorTheme()
}

extension EnvironmentValues {
    /// The current theme.
    ///
    /// Set a theme at the app level and it propagates to all child views:
    ///
    /// ```swift
    /// WindowGroup {
    ///     ContentView()
    /// }
    /// .environment(\.theme, GreenPhosphorTheme())
    /// ```
    ///
    /// Access the theme in views:
    ///
    /// ```swift
    /// struct MyView: View {
    ///     @Environment(\.theme) var theme
    ///
    ///     var body: some View {
    ///         Text("Hello")
    ///             .foregroundColor(theme.foreground)
    ///     }
    /// }
    /// ```
    public var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Color Theme Extension

extension Color {
    /// Access theme colors from the current environment.
    ///
    /// These colors read from `EnvironmentStorage.shared` during rendering.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Hello").foregroundColor(.theme.foreground)
    /// ```
    public static var theme: ThemeColors.Type {
        ThemeColors.self
    }
}

/// Namespace for theme-aware colors.
///
/// These properties read the current theme from the environment storage
/// that is set during rendering.
public enum ThemeColors {
    /// Gets the current theme from environment storage.
    private static var current: Theme {
        EnvironmentStorage.shared.environment.theme
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

    /// Disabled color.
    public static var disabled: Color { current.disabled }

    /// Status bar background.
    public static var statusBarBackground: Color { current.statusBarBackground }

    /// Status bar foreground.
    public static var statusBarForeground: Color { current.statusBarForeground }

    /// Status bar highlight.
    public static var statusBarHighlight: Color { current.statusBarHighlight }
}

// MARK: - Theme Modifier

extension View {
    /// Sets the theme for this view and its descendants.
    ///
    /// # Example
    ///
    /// ```swift
    /// ContentView()
    ///     .theme(GreenPhosphorTheme())
    /// ```
    ///
    /// - Parameter theme: The theme to apply.
    /// - Returns: A view with the theme applied.
    public func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}

// MARK: - Predefined Themes

/// Classic green phosphor terminal theme (P1 phosphor).
///
/// Inspired by early CRT monitors like the IBM 5151 and Apple II.
/// Uses a neutral dark background with green text - like classic terminals.
public struct GreenPhosphorTheme: Theme {
    public let id = "green-phosphor"
    public let name = "Green"

    // Neutral dark background (like Spotnik reference)
    public let background = Color.hex(0x1E1E1E)
    public let backgroundSecondary = Color.hex(0x282828)
    public let backgroundTertiary = Color.hex(0x141414)
    
    // Green phosphor text hierarchy
    public let foreground = Color.hex(0x33FF33)           // Bright green - primary text
    public let foregroundSecondary = Color.hex(0x29CC29)  // Medium green - secondary text
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
    public let selection = Color.hex(0x1F4D1F)            // Dark green for selection bg
    
    // Status bar
    public let statusBarBackground = Color.hex(0x282828)
    public let statusBarForeground = Color.hex(0x33FF33)
    public let statusBarHighlight = Color.hex(0x66FF66)

    public init() {}
}

/// Classic amber phosphor terminal theme (P3 phosphor).
///
/// Inspired by terminals like the IBM 3278 and Wyse 50.
/// Matches the Spotnik app reference with neutral background and amber text.
public struct AmberPhosphorTheme: Theme {
    public let id = "amber-phosphor"
    public let name = "Amber"

    // Neutral dark background (exactly like Spotnik reference)
    public let background = Color.hex(0x1E1E1E)
    public let backgroundSecondary = Color.hex(0x282828)
    public let backgroundTertiary = Color.hex(0x141414)
    
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
    public let selection = Color.hex(0x4D3A1F)            // Dark amber for selection bg
    
    // Status bar
    public let statusBarBackground = Color.hex(0x282828)
    public let statusBarForeground = Color.hex(0xFFAA00)
    public let statusBarHighlight = Color.hex(0xFFCC33)

    public init() {}
}

/// Classic white phosphor terminal theme (P4 phosphor).
///
/// Inspired by terminals like the DEC VT100 and VT220.
/// Clean monochrome look with neutral background.
public struct WhitePhosphorTheme: Theme {
    public let id = "white-phosphor"
    public let name = "White"

    // Neutral dark background
    public let background = Color.hex(0x1E1E1E)
    public let backgroundSecondary = Color.hex(0x282828)
    public let backgroundTertiary = Color.hex(0x141414)
    
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
    public let selection = Color.hex(0x3A3A3A)            // Dark gray for selection bg
    
    // Status bar
    public let statusBarBackground = Color.hex(0x282828)
    public let statusBarForeground = Color.hex(0xE8E8E8)
    public let statusBarHighlight = Color.hex(0xFFFFFF)

    public init() {}
}

/// Red phosphor terminal theme.
///
/// Less common but used in some military and specialized applications.
/// Night-vision friendly with reduced eye strain in dark environments.
public struct RedPhosphorTheme: Theme {
    public let id = "red-phosphor"
    public let name = "Red"

    // Neutral dark background
    public let background = Color.hex(0x1E1E1E)
    public let backgroundSecondary = Color.hex(0x282828)
    public let backgroundTertiary = Color.hex(0x141414)
    
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
    public let selection = Color.hex(0x4D1F1F)            // Dark red for selection bg
    
    // Status bar
    public let statusBarBackground = Color.hex(0x282828)
    public let statusBarForeground = Color.hex(0xFF4444)
    public let statusBarHighlight = Color.hex(0xFF6666)

    public init() {}
}

/// Classic ncurses-style theme.
///
/// Traditional terminal colors as used in ncurses applications
/// like htop, mc (Midnight Commander), and vim.
public struct NCursesTheme: Theme {
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
    public let selection = Color.blue
    public let disabled = Color.brightBlack
    public let statusBarBackground = Color.blue
    public let statusBarForeground = Color.white
    public let statusBarHighlight = Color.yellow

    public init() {}
}

// MARK: - Theme Registry

/// Registry of available themes.
public struct ThemeRegistry {
    /// All available themes in cycling order.
    ///
    /// Order: Green → Amber → White → Red → NCurses
    public static let all: [Theme] = [
        GreenPhosphorTheme(),
        AmberPhosphorTheme(),
        WhitePhosphorTheme(),
        RedPhosphorTheme(),
        NCursesTheme()
    ]

    /// Finds a theme by ID.
    public static func theme(withId id: String) -> Theme? {
        all.first { $0.id == id }
    }

    /// Finds a theme by name.
    public static func theme(withName name: String) -> Theme? {
        all.first { $0.name == name }
    }
}

// MARK: - Convenience Theme Accessors

extension Theme where Self == GreenPhosphorTheme {
    /// The default theme (green phosphor).
    public static var `default`: GreenPhosphorTheme { GreenPhosphorTheme() }
    /// Green phosphor terminal theme.
    public static var green: GreenPhosphorTheme { GreenPhosphorTheme() }
    /// Green phosphor terminal theme (alias).
    public static var greenPhosphor: GreenPhosphorTheme { GreenPhosphorTheme() }
}

extension Theme where Self == AmberPhosphorTheme {
    /// Amber phosphor terminal theme.
    public static var amber: AmberPhosphorTheme { AmberPhosphorTheme() }
    /// Amber phosphor terminal theme (alias).
    public static var amberPhosphor: AmberPhosphorTheme { AmberPhosphorTheme() }
}

extension Theme where Self == WhitePhosphorTheme {
    /// White phosphor terminal theme.
    public static var white: WhitePhosphorTheme { WhitePhosphorTheme() }
    /// White phosphor terminal theme (alias).
    public static var whitePhosphor: WhitePhosphorTheme { WhitePhosphorTheme() }
}

extension Theme where Self == RedPhosphorTheme {
    /// Red phosphor terminal theme.
    public static var red: RedPhosphorTheme { RedPhosphorTheme() }
    /// Red phosphor terminal theme (alias).
    public static var redPhosphor: RedPhosphorTheme { RedPhosphorTheme() }
}

extension Theme where Self == NCursesTheme {
    /// Classic ncurses theme.
    public static var ncurses: NCursesTheme { NCursesTheme() }
}

// MARK: - Theme Manager

/// Manages theme cycling for the application.
///
/// The `ThemeManager` provides methods to cycle through available themes
/// and set specific themes. It works with the environment system to update
/// the current theme and trigger re-renders.
///
/// # Usage
///
/// Access via environment:
///
/// ```swift
/// @Environment(\.themeManager) var themeManager
///
/// // Cycle to the next theme
/// themeManager.cycleTheme()
///
/// // Set a specific theme
/// themeManager.setTheme(.amber)
/// themeManager.setTheme(.greenPhosphor)
///
/// // Get the current theme
/// let theme = themeManager.currentTheme
/// ```
public final class ThemeManager: @unchecked Sendable {
    /// The current theme index.
    private var currentIndex: Int = 0
    
    /// All available themes.
    public let availableThemes: [Theme]
    
    /// Creates a new theme manager with the default themes.
    public init() {
        self.availableThemes = ThemeRegistry.all
    }
    
    /// Creates a new theme manager with custom themes.
    ///
    /// - Parameter themes: The themes to cycle through.
    public init(themes: [Theme]) {
        self.availableThemes = themes.isEmpty ? ThemeRegistry.all : themes
    }
    
    /// The current theme.
    public var currentTheme: Theme {
        availableThemes[currentIndex]
    }
    
    /// The name of the current theme.
    public var currentThemeName: String {
        currentTheme.name
    }
    
    /// Cycles to the next theme.
    ///
    /// Updates the environment and triggers a re-render.
    public func cycleTheme() {
        currentIndex = (currentIndex + 1) % availableThemes.count
        applyCurrentTheme()
    }
    
    /// Cycles to the previous theme.
    ///
    /// Updates the environment and triggers a re-render.
    public func cyclePreviousTheme() {
        currentIndex = (currentIndex - 1 + availableThemes.count) % availableThemes.count
        applyCurrentTheme()
    }
    
    /// Sets a specific theme.
    ///
    /// - Parameter theme: The theme to set.
    ///
    /// # Example
    ///
    /// ```swift
    /// themeManager.setTheme(.amber)
    /// themeManager.setTheme(.greenPhosphor)
    /// themeManager.setTheme(.dark)
    /// ```
    public func setTheme(_ theme: Theme) {
        if let index = availableThemes.firstIndex(where: { $0.id == theme.id }) {
            currentIndex = index
        } else {
            // Theme not in list, add temporarily at current position
            currentIndex = 0
        }
        
        // Apply the theme directly (even if not in availableThemes)
        var environment = EnvironmentStorage.shared.environment
        environment.theme = theme
        EnvironmentStorage.shared.environment = environment
        AppState.shared.setNeedsRender()
    }
    
    /// Applies the current theme to the environment and triggers a re-render.
    private func applyCurrentTheme() {
        var environment = EnvironmentStorage.shared.environment
        environment.theme = currentTheme
        EnvironmentStorage.shared.environment = environment
        AppState.shared.setNeedsRender()
    }
}

// MARK: - ThemeManager Environment Key

/// Environment key for the theme manager.
private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue: ThemeManager = ThemeManager()
}

extension EnvironmentValues {
    /// The theme manager for cycling and setting themes.
    ///
    /// ```swift
    /// @Environment(\.themeManager) var themeManager
    ///
    /// themeManager.cycleTheme()
    /// themeManager.setTheme(.amber)
    /// ```
    public var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}
