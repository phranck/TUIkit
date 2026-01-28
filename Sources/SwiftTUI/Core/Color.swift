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

    /// Creates a color from a hex string.
    ///
    /// Supports formats: "#RGB", "#RRGGBB", "RGB", "RRGGBB"
    ///
    /// - Parameter hex: The hex string (e.g., "#FF5500", "F50", "#abc").
    /// - Returns: The corresponding RGB color, or nil if invalid.
    public static func hex(_ hex: String) -> Color? {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove # prefix if present
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        // Handle shorthand format (RGB -> RRGGBB)
        if hexString.count == 3 {
            let chars = Array(hexString)
            hexString = String([chars[0], chars[0], chars[1], chars[1], chars[2], chars[2]])
        }

        // Must be 6 characters now
        guard hexString.count == 6 else { return nil }

        // Parse hex value
        guard let hexValue = UInt32(hexString, radix: 16) else { return nil }

        return .hex(hexValue)
    }

    /// Creates a color from HSL values.
    ///
    /// - Parameters:
    ///   - hue: The hue component (0-360).
    ///   - saturation: The saturation component (0-100).
    ///   - lightness: The lightness component (0-100).
    /// - Returns: The corresponding RGB color.
    public static func hsl(_ hue: Double, _ saturation: Double, _ lightness: Double) -> Color {
        let h = hue / 360.0
        let s = saturation / 100.0
        let l = lightness / 100.0

        if s == 0 {
            // Achromatic (gray)
            let gray = UInt8(l * 255)
            return .rgb(gray, gray, gray)
        }

        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q

        func hueToRGB(_ p: Double, _ q: Double, _ t: Double) -> Double {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1/6 { return p + (q - p) * 6 * t }
            if t < 1/2 { return q }
            if t < 2/3 { return p + (q - p) * (2/3 - t) * 6 }
            return p
        }

        let red = UInt8(hueToRGB(p, q, h + 1/3) * 255)
        let green = UInt8(hueToRGB(p, q, h) * 255)
        let blue = UInt8(hueToRGB(p, q, h - 1/3) * 255)

        return .rgb(red, green, blue)
    }

    /// Returns a lighter version of this color.
    ///
    /// - Parameter amount: The amount to lighten (0-1, default 0.2).
    /// - Returns: A lighter color.
    public func lighter(by amount: Double = 0.2) -> Color {
        guard case .rgb(let red, let green, let blue) = value else {
            return self
        }

        let newRed = UInt8(min(255, Double(red) + 255 * amount))
        let newGreen = UInt8(min(255, Double(green) + 255 * amount))
        let newBlue = UInt8(min(255, Double(blue) + 255 * amount))

        return .rgb(newRed, newGreen, newBlue)
    }

    /// Returns a darker version of this color.
    ///
    /// - Parameter amount: The amount to darken (0-1, default 0.2).
    /// - Returns: A darker color.
    public func darker(by amount: Double = 0.2) -> Color {
        guard case .rgb(let red, let green, let blue) = value else {
            return self
        }

        let newRed = UInt8(max(0, Double(red) - 255 * amount))
        let newGreen = UInt8(max(0, Double(green) - 255 * amount))
        let newBlue = UInt8(max(0, Double(blue) - 255 * amount))

        return .rgb(newRed, newGreen, newBlue)
    }

    /// Returns a color with adjusted opacity (simulated via color mixing).
    ///
    /// Since terminals don't support true transparency, this mixes
    /// the color with black to simulate opacity.
    ///
    /// - Parameter opacity: The opacity (0-1).
    /// - Returns: A color simulating the given opacity.
    public func opacity(_ opacity: Double) -> Color {
        guard case .rgb(let red, let green, let blue) = value else {
            return self
        }

        let newRed = UInt8(Double(red) * opacity)
        let newGreen = UInt8(Double(green) * opacity)
        let newBlue = UInt8(Double(blue) * opacity)

        return .rgb(newRed, newGreen, newBlue)
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
