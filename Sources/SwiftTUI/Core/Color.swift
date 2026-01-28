//
//  Color.swift
//  SwiftTUI
//
//  Color definitions for terminal output with ANSI escape codes.
//

/// A color for use in SwiftTUI views.
///
/// `Color` represents standard ANSI colors as well as
/// extended 256-color palette and True Color (24-bit RGB).
///
/// # Standard Colors
///
/// ```swift
/// Text("Red").foregroundColor(.red)
/// Text("Green").foregroundColor(.green)
/// Text("Blue").foregroundColor(.blue)
/// ```
///
/// # RGB Colors
///
/// ```swift
/// Text("Custom").foregroundColor(.rgb(255, 128, 0))
/// ```
public struct Color: Sendable, Equatable {
    /// The internal color value.
    let value: ColorValue

    /// Internal enum for different color types.
    enum ColorValue: Sendable, Equatable {
        case standard(ANSIColor)
        case bright(ANSIColor)
        case palette256(UInt8)
        case rgb(red: UInt8, green: UInt8, blue: UInt8)
    }

    // MARK: - Standard ANSI Colors

    /// Black (ANSI 30/40)
    public static let black = Color(value: .standard(.black))

    /// Red (ANSI 31/41)
    public static let red = Color(value: .standard(.red))

    /// Green (ANSI 32/42)
    public static let green = Color(value: .standard(.green))

    /// Yellow (ANSI 33/43)
    public static let yellow = Color(value: .standard(.yellow))

    /// Blue (ANSI 34/44)
    public static let blue = Color(value: .standard(.blue))

    /// Magenta (ANSI 35/45)
    public static let magenta = Color(value: .standard(.magenta))

    /// Cyan (ANSI 36/46)
    public static let cyan = Color(value: .standard(.cyan))

    /// White (ANSI 37/47)
    public static let white = Color(value: .standard(.white))

    /// Default color (terminal default)
    public static let `default` = Color(value: .standard(.`default`))

    // MARK: - Bright ANSI Colors

    /// Bright black (gray)
    public static let brightBlack = Color(value: .bright(.black))

    /// Bright red
    public static let brightRed = Color(value: .bright(.red))

    /// Bright green
    public static let brightGreen = Color(value: .bright(.green))

    /// Bright yellow
    public static let brightYellow = Color(value: .bright(.yellow))

    /// Bright blue
    public static let brightBlue = Color(value: .bright(.blue))

    /// Bright magenta
    public static let brightMagenta = Color(value: .bright(.magenta))

    /// Bright cyan
    public static let brightCyan = Color(value: .bright(.cyan))

    /// Bright white
    public static let brightWhite = Color(value: .bright(.white))

    // MARK: - Semantic Colors

    /// Primary color (default: blue)
    public static let primary = Color.blue

    /// Secondary color (default: gray)
    public static let secondary = Color.brightBlack

    /// Accent color (default: cyan)
    public static let accent = Color.cyan

    /// Warning color
    public static let warning = Color.yellow

    /// Error color
    public static let error = Color.red

    /// Success color
    public static let success = Color.green

    // MARK: - Custom Colors

    /// Creates a color from the 256-color palette.
    ///
    /// - Parameter index: The palette index (0-255).
    /// - Returns: The corresponding color.
    public static func palette(_ index: UInt8) -> Color {
        Color(value: .palette256(index))
    }

    /// Creates a True Color RGB color.
    ///
    /// - Parameters:
    ///   - red: The red component (0-255).
    ///   - green: The green component (0-255).
    ///   - blue: The blue component (0-255).
    /// - Returns: The RGB color.
    public static func rgb(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> Color {
        Color(value: .rgb(red: red, green: green, blue: blue))
    }

    /// Creates a color from a hex value.
    ///
    /// - Parameter hex: The hex value (e.g., 0xFF5500).
    /// - Returns: The corresponding RGB color.
    public static func hex(_ hex: UInt32) -> Color {
        let red = UInt8((hex >> 16) & 0xFF)
        let green = UInt8((hex >> 8) & 0xFF)
        let blue = UInt8(hex & 0xFF)
        return .rgb(red, green, blue)
    }
}

// MARK: - ANSIColor

/// The 8 standard ANSI colors.
public enum ANSIColor: UInt8, Sendable {
    case black = 0
    case red = 1
    case green = 2
    case yellow = 3
    case blue = 4
    case magenta = 5
    case cyan = 6
    case white = 7
    case `default` = 9

    /// The ANSI code for foreground color (30-37, 39 for default).
    public var foregroundCode: UInt8 {
        30 + rawValue
    }

    /// The ANSI code for background color (40-47, 49 for default).
    public var backgroundCode: UInt8 {
        40 + rawValue
    }

    /// The ANSI code for bright foreground color (90-97).
    public var brightForegroundCode: UInt8 {
        90 + rawValue
    }

    /// The ANSI code for bright background color (100-107).
    public var brightBackgroundCode: UInt8 {
        100 + rawValue
    }
}
