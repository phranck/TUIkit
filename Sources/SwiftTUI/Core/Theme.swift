//
//  Theme.swift
//  SwiftTUI
//
//  Theming system with full 16M color support and predefined terminal themes.
//

import Foundation

// MARK: - Theme Protocol

/// A theme defines the color palette for a SwiftTUI application.
///
/// Themes provide semantic colors that views use for consistent styling.
/// SwiftTUI includes several predefined themes inspired by classic terminals.
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
    static let defaultValue: Theme = DefaultTheme()
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

/// The default theme using standard ANSI colors.
public struct DefaultTheme: Theme {
    public let id = "default"
    public let name = "Default"

    public let background = Color.default
    public let backgroundSecondary = Color.brightBlack
    public let foreground = Color.white
    public let foregroundSecondary = Color.brightWhite
    public let foregroundTertiary = Color.brightBlack
    public let accent = Color.cyan
    public let accentSecondary = Color.blue
    public let success = Color.green
    public let warning = Color.yellow
    public let error = Color.red
    public let info = Color.cyan
    public let border = Color.brightBlack
    public let statusBarHighlight = Color.cyan

    public init() {}
}

/// Classic green phosphor terminal theme (P1 phosphor).
///
/// Inspired by early CRT monitors like the IBM 5151 and Apple II.
public struct GreenPhosphorTheme: Theme {
    public let id = "green-phosphor"
    public let name = "Green (Phosphor)"

    // Dark background with green phosphor glow
    public let background = Color.hex(0x0D1F0D)
    public let backgroundSecondary = Color.hex(0x0A1A0A)
    public let backgroundTertiary = Color.hex(0x071407)
    public let foreground = Color.hex(0x33FF33)
    public let foregroundSecondary = Color.hex(0x29CC29)
    public let foregroundTertiary = Color.hex(0x1F991F)
    public let accent = Color.hex(0x66FF66)
    public let accentSecondary = Color.hex(0x00CC00)
    public let success = Color.hex(0x33FF33)
    public let warning = Color.hex(0xCCFF33)
    public let error = Color.hex(0xFF6633)
    public let info = Color.hex(0x33FFCC)
    public let border = Color.hex(0x1F661F)
    public let borderFocused = Color.hex(0x33FF33)
    public let selection = Color.hex(0x1F4D1F)
    public let statusBarBackground = Color.hex(0x0A1A0A)
    public let statusBarForeground = Color.hex(0x33FF33)
    public let statusBarHighlight = Color.hex(0x66FF66)

    public init() {}
}

/// Classic amber phosphor terminal theme (P3 phosphor).
///
/// Inspired by terminals like the IBM 3278 and Wyse 50.
public struct AmberPhosphorTheme: Theme {
    public let id = "amber-phosphor"
    public let name = "Amber (Phosphor)"

    // Dark background with amber phosphor glow
    public let background = Color.hex(0x1F1400)
    public let backgroundSecondary = Color.hex(0x1A1100)
    public let backgroundTertiary = Color.hex(0x140D00)
    public let foreground = Color.hex(0xFFB000)
    public let foregroundSecondary = Color.hex(0xCC8C00)
    public let foregroundTertiary = Color.hex(0x996900)
    public let accent = Color.hex(0xFFCC33)
    public let accentSecondary = Color.hex(0xCC9900)
    public let success = Color.hex(0xFFCC00)
    public let warning = Color.hex(0xFFE066)
    public let error = Color.hex(0xFF6633)
    public let info = Color.hex(0xFFD966)
    public let border = Color.hex(0x664D00)
    public let borderFocused = Color.hex(0xFFB000)
    public let selection = Color.hex(0x4D3A00)
    public let statusBarBackground = Color.hex(0x1A1100)
    public let statusBarForeground = Color.hex(0xFFB000)
    public let statusBarHighlight = Color.hex(0xFFCC33)

    public init() {}
}

/// Classic white phosphor terminal theme (P4 phosphor).
///
/// Inspired by terminals like the DEC VT100 and VT220.
public struct WhitePhosphorTheme: Theme {
    public let id = "white-phosphor"
    public let name = "White (Phosphor)"

    // Dark background with white/cool phosphor glow
    public let background = Color.hex(0x0A0A0F)
    public let backgroundSecondary = Color.hex(0x12121A)
    public let backgroundTertiary = Color.hex(0x080810)
    public let foreground = Color.hex(0xE0E0E8)
    public let foregroundSecondary = Color.hex(0xB0B0B8)
    public let foregroundTertiary = Color.hex(0x808088)
    public let accent = Color.hex(0xF0F0FF)
    public let accentSecondary = Color.hex(0xC0C0D0)
    public let success = Color.hex(0xC0FFC0)
    public let warning = Color.hex(0xFFE0A0)
    public let error = Color.hex(0xFFA0A0)
    public let info = Color.hex(0xA0E0FF)
    public let border = Color.hex(0x404050)
    public let borderFocused = Color.hex(0xE0E0E8)
    public let selection = Color.hex(0x303040)
    public let statusBarBackground = Color.hex(0x12121A)
    public let statusBarForeground = Color.hex(0xE0E0E8)
    public let statusBarHighlight = Color.hex(0xF0F0FF)

    public init() {}
}

/// Red phosphor terminal theme.
///
/// Less common but used in some military and specialized applications.
public struct RedPhosphorTheme: Theme {
    public let id = "red-phosphor"
    public let name = "Red (Phosphor)"

    // Dark background with red phosphor glow
    public let background = Color.hex(0x1A0A0A)
    public let backgroundSecondary = Color.hex(0x140808)
    public let backgroundTertiary = Color.hex(0x100606)
    public let foreground = Color.hex(0xFF4040)
    public let foregroundSecondary = Color.hex(0xCC3333)
    public let foregroundTertiary = Color.hex(0x992626)
    public let accent = Color.hex(0xFF6666)
    public let accentSecondary = Color.hex(0xCC4040)
    public let success = Color.hex(0xFF8080)
    public let warning = Color.hex(0xFFB366)
    public let error = Color.hex(0xFFFFFF)
    public let info = Color.hex(0xFF9999)
    public let border = Color.hex(0x661A1A)
    public let borderFocused = Color.hex(0xFF4040)
    public let selection = Color.hex(0x4D1414)
    public let statusBarBackground = Color.hex(0x140808)
    public let statusBarForeground = Color.hex(0xFF4040)
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

/// Dark mode theme with modern colors.
public struct DarkTheme: Theme {
    public let id = "dark"
    public let name = "Dark"

    public let background = Color.hex(0x1E1E2E)
    public let backgroundSecondary = Color.hex(0x313244)
    public let backgroundTertiary = Color.hex(0x45475A)
    public let foreground = Color.hex(0xCDD6F4)
    public let foregroundSecondary = Color.hex(0xBAC2DE)
    public let foregroundTertiary = Color.hex(0xA6ADC8)
    public let accent = Color.hex(0x89B4FA)
    public let accentSecondary = Color.hex(0x74C7EC)
    public let success = Color.hex(0xA6E3A1)
    public let warning = Color.hex(0xF9E2AF)
    public let error = Color.hex(0xF38BA8)
    public let info = Color.hex(0x89DCEB)
    public let border = Color.hex(0x585B70)
    public let borderFocused = Color.hex(0x89B4FA)
    public let selection = Color.hex(0x45475A)
    public let statusBarBackground = Color.hex(0x313244)
    public let statusBarForeground = Color.hex(0xCDD6F4)
    public let statusBarHighlight = Color.hex(0x89B4FA)

    public init() {}
}

/// Light mode theme.
public struct LightTheme: Theme {
    public let id = "light"
    public let name = "Light"

    public let background = Color.hex(0xEFF1F5)
    public let backgroundSecondary = Color.hex(0xE6E9EF)
    public let backgroundTertiary = Color.hex(0xDCE0E8)
    public let foreground = Color.hex(0x4C4F69)
    public let foregroundSecondary = Color.hex(0x5C5F77)
    public let foregroundTertiary = Color.hex(0x6C6F85)
    public let accent = Color.hex(0x1E66F5)
    public let accentSecondary = Color.hex(0x209FB5)
    public let success = Color.hex(0x40A02B)
    public let warning = Color.hex(0xDF8E1D)
    public let error = Color.hex(0xD20F39)
    public let info = Color.hex(0x04A5E5)
    public let border = Color.hex(0x9CA0B0)
    public let borderFocused = Color.hex(0x1E66F5)
    public let selection = Color.hex(0xDCE0E8)
    public let statusBarBackground = Color.hex(0xE6E9EF)
    public let statusBarForeground = Color.hex(0x4C4F69)
    public let statusBarHighlight = Color.hex(0x1E66F5)

    public init() {}
}

// MARK: - Theme Registry

/// Registry of available themes.
public struct ThemeRegistry {
    /// All available themes.
    public static let all: [Theme] = [
        DefaultTheme(),
        GreenPhosphorTheme(),
        AmberPhosphorTheme(),
        WhitePhosphorTheme(),
        RedPhosphorTheme(),
        NCursesTheme(),
        DarkTheme(),
        LightTheme()
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

extension Theme where Self == DefaultTheme {
    /// The default theme.
    public static var `default`: DefaultTheme { DefaultTheme() }
}

extension Theme where Self == GreenPhosphorTheme {
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

extension Theme where Self == DarkTheme {
    /// Modern dark theme.
    public static var dark: DarkTheme { DarkTheme() }
}

extension Theme where Self == LightTheme {
    /// Modern light theme.
    public static var light: LightTheme { LightTheme() }
}
