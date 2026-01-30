//
//  Color.swift
//  TUIKit
//
//  Color definitions for terminal output with ANSI escape codes.
//

/// A color for use in TUIKit views.
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
    public static let black = Self(value: .standard(.black))

    /// Red (ANSI 31/41)
    public static let red = Self(value: .standard(.red))

    /// Green (ANSI 32/42)
    public static let green = Self(value: .standard(.green))

    /// Yellow (ANSI 33/43)
    public static let yellow = Self(value: .standard(.yellow))

    /// Blue (ANSI 34/44)
    public static let blue = Self(value: .standard(.blue))

    /// Magenta (ANSI 35/45)
    public static let magenta = Self(value: .standard(.magenta))

    /// Cyan (ANSI 36/46)
    public static let cyan = Self(value: .standard(.cyan))

    /// White (ANSI 37/47)
    public static let white = Self(value: .standard(.white))

    /// Default color (terminal default)
    public static let `default` = Self(value: .standard(.`default`))

    // MARK: - Bright ANSI Colors

    /// Bright black (gray)
    public static let brightBlack = Self(value: .bright(.black))

    /// Bright red
    public static let brightRed = Self(value: .bright(.red))

    /// Bright green
    public static let brightGreen = Self(value: .bright(.green))

    /// Bright yellow
    public static let brightYellow = Self(value: .bright(.yellow))

    /// Bright blue
    public static let brightBlue = Self(value: .bright(.blue))

    /// Bright magenta
    public static let brightMagenta = Self(value: .bright(.magenta))

    /// Bright cyan
    public static let brightCyan = Self(value: .bright(.cyan))

    /// Bright white
    public static let brightWhite = Self(value: .bright(.white))

    // MARK: - Semantic Colors

    /// Primary color (default: blue)
    public static let primary = Self.blue

    /// Secondary color (default: gray)
    public static let secondary = Self.brightBlack

    /// Accent color (default: cyan)
    public static let accent = Self.cyan

    /// Warning color
    public static let warning = Self.yellow

    /// Error color
    public static let error = Self.red

    /// Success color
    public static let success = Self.green

    // MARK: - Custom Colors

    /// Creates a color from the 256-color palette.
    ///
    /// - Parameter index: The palette index (0-255).
    /// - Returns: The corresponding color.
    public static func palette(_ index: UInt8) -> Self {
        Self(value: .palette256(index))
    }

    /// Creates a True Color RGB color.
    ///
    /// - Parameters:
    ///   - red: The red component (0-255).
    ///   - green: The green component (0-255).
    ///   - blue: The blue component (0-255).
    /// - Returns: The RGB color.
    public static func rgb(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> Self {
        Self(value: .rgb(red: red, green: green, blue: blue))
    }

    /// Creates a color from a hex value.
    ///
    /// - Parameter hex: The hex value (e.g., 0xFF5500).
    /// - Returns: The corresponding RGB color.
    public static func hex(_ hex: UInt32) -> Self {
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
    public static func hex(_ hex: String) -> Self? {
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
    public static func hsl(_ hue: Double, _ saturation: Double, _ lightness: Double) -> Self {
        let normalizedHue = hue / 360.0
        let normalizedSaturation = saturation / 100.0
        let normalizedLightness = lightness / 100.0

        if normalizedSaturation == 0 {
            // Achromatic (gray)
            let gray = UInt8(normalizedLightness * 255)
            return .rgb(gray, gray, gray)
        }

        let chromaFactor = normalizedLightness < 0.5
            ? normalizedLightness * (1 + normalizedSaturation)
            : normalizedLightness + normalizedSaturation - normalizedLightness * normalizedSaturation
        let luminanceFactor = 2 * normalizedLightness - chromaFactor

        func hueToRGB(_ luminance: Double, _ chroma: Double, _ hueComponent: Double) -> Double {
            var adjustedHue = hueComponent
            if adjustedHue < 0 { adjustedHue += 1 }
            if adjustedHue > 1 { adjustedHue -= 1 }
            if adjustedHue < 1 / 6 { return luminance + (chroma - luminance) * 6 * adjustedHue }
            if adjustedHue < 1 / 2 { return chroma }
            if adjustedHue < 2 / 3 { return luminance + (chroma - luminance) * (2 / 3 - adjustedHue) * 6 }
            return luminance
        }

        let red = UInt8(hueToRGB(luminanceFactor, chromaFactor, normalizedHue + 1 / 3) * 255)
        let green = UInt8(hueToRGB(luminanceFactor, chromaFactor, normalizedHue) * 255)
        let blue = UInt8(hueToRGB(luminanceFactor, chromaFactor, normalizedHue - 1 / 3) * 255)

        return .rgb(red, green, blue)
    }

    /// Returns a lighter version of this color.
    ///
    /// - Parameter amount: The amount to lighten (0-1, default 0.2).
    /// - Returns: A lighter color.
    public func lighter(by amount: Double = 0.2) -> Self {
        adjusted(by: amount)
    }

    /// Returns a darker version of this color.
    ///
    /// - Parameter amount: The amount to darken (0-1, default 0.2).
    /// - Returns: A darker color.
    public func darker(by amount: Double = 0.2) -> Self {
        adjusted(by: -amount)
    }

    /// Adjusts brightness by a signed amount.
    ///
    /// Positive values lighten, negative values darken.
    ///
    /// - Parameter amount: The adjustment amount (-1 to 1).
    /// - Returns: The adjusted color, or self if not an RGB color.
    private func adjusted(by amount: Double) -> Self {
        guard case .rgb(let red, let green, let blue) = value else {
            return self
        }

        let shift = 255 * amount
        let newRed = UInt8(min(255, max(0, Double(red) + shift)))
        let newGreen = UInt8(min(255, max(0, Double(green) + shift)))
        let newBlue = UInt8(min(255, max(0, Double(blue) + shift)))

        return .rgb(newRed, newGreen, newBlue)
    }

    /// Returns a color with adjusted opacity (simulated via color mixing).
    ///
    /// Since terminals don't support true transparency, this mixes
    /// the color with black to simulate opacity.
    ///
    /// - Parameter opacity: The opacity (0-1).
    /// - Returns: A color simulating the given opacity.
    public func opacity(_ opacity: Double) -> Self {
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
