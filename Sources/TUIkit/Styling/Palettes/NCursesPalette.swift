//
//  NCursesPalette.swift
//  TUIkit
//
//  Classic ncurses-style palette.
//

/// Classic ncurses-style palette.
///
/// Traditional terminal colors as used in ncurses applications
/// like htop, mc (Midnight Commander), and vim.
public struct NCursesPalette: Palette {
    public let id = "ncurses"
    public let name = "ncurses"

    // Standard terminal black background
    public let background = Color.black
    public let containerBodyBackground = Color.blue
    public let containerCapBackground = Color.brightBlack
    public let foreground = Color.white
    public let foregroundSecondary = Color.brightWhite
    public let foregroundTertiary = Color.brightBlack
    public let foregroundPlaceholder = Color.brightBlack
    public let accent = Color.cyan
    public let accentSecondary = Color.brightCyan
    public let success = Color.green
    public let warning = Color.yellow
    public let error = Color.red
    public let info = Color.cyan
    public let border = Color.white
    public let disabled = Color.brightBlack
    public let statusBarBackground = Color.blue
    public let appHeaderBackground = Color.brightBlack
    public let overlayBackground = Color.black
    public var buttonBackground: Color { Color.brightBlue }

    public init() {}
}

// MARK: - Convenience Accessors

extension Palette where Self == NCursesPalette {
    /// Classic ncurses palette.
    public static var ncurses: NCursesPalette { NCursesPalette() }
}
