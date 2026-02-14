//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PalettePreset.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - System Palette

/// A palette generated from a built-in ``Preset``.
///
/// All colors are derived algorithmically from the preset's base hue
/// and hand-tuned HSL parameters. This single type replaces the six
/// individual palette structs (`GreenPalette`, `AmberPalette`, etc.).
///
/// Custom palettes should conform to ``Palette`` directly instead of using
/// this type.
///
/// # Usage
///
/// ```swift
/// let palette = SystemPalette(.amber)
/// paletteManager.setCurrent(SystemPalette(.green))
/// ```
public struct SystemPalette: Palette {
    // MARK: - Preset

    /// Built-in palette presets inspired by classic terminal phosphors.
    ///
    /// | Preset   | Hue  | Inspiration                                |
    /// |----------|------|--------------------------------------------|
    /// | `green`  | 120° | IBM 5151, Apple II (P1 phosphor)           |
    /// | `amber`  |  40° | IBM 3278, Wyse 50 (P3 phosphor)            |
    /// | `red`    |   0° | Military/specialized, night-vision         |
    /// | `violet` | 270° | Retro computing, sci-fi terminals          |
    /// | `blue`   | 200° | Vacuum fluorescent displays (VFDs)         |
    /// | `white`  | 225° | DEC VT100/VT220 (P4 phosphor)              |
    public enum Preset: String, CaseIterable, Sendable {
        case green
        case amber
        case red
        case violet
        case blue
        case white
    }

    public let id: String
    public let name: String

    // Background
    public let background: Color

    // Foreground hierarchy
    public let foreground: Color
    public let foregroundSecondary: Color
    public let foregroundTertiary: Color
    public let foregroundQuaternary: Color

    // Accent
    public let accent: Color

    // Semantic colors
    public let success: Color
    public let warning: Color
    public let error: Color
    public let info: Color

    // UI elements
    public let border: Color
    public let focusBackground: Color
    public let cursorColor: Color

    // Additional backgrounds
    public let statusBarBackground: Color
    public let appHeaderBackground: Color
    public let overlayBackground: Color

    /// Creates a palette from a preset.
    ///
    /// - Parameter preset: The built-in preset to use.
    public init(_ preset: Preset) {
        let tuning = Tuning.for(preset)
        let hue = tuning.baseHue

        self.id = preset.rawValue
        self.name = preset.rawValue.capitalized

        // Backgrounds
        self.background = Color.hsl(hue, tuning.bgSaturation, 3)
        self.statusBarBackground = Color.hsl(hue, tuning.barSaturation, 10)
        self.appHeaderBackground = Color.hsl(hue, tuning.barSaturation, 7)
        self.overlayBackground = Color.hsl(hue, tuning.bgSaturation, 3)

        // Foregrounds
        self.foreground = Color.hsl(tuning.fgHue, tuning.fgSaturation, tuning.fgLightness)
        self.foregroundSecondary = Color.hsl(tuning.fgHue, tuning.fgSecSaturation, tuning.fgSecLightness)
        self.foregroundTertiary = Color.hsl(tuning.fgHue, tuning.fgTerSaturation, tuning.fgTerLightness)
        self.foregroundQuaternary = Color.hsl(tuning.fgHue, tuning.fgQuatSaturation, tuning.fgQuatLightness)

        // Accent
        self.accent = Color.hsl(tuning.accentHue, tuning.accentSaturation, tuning.accentLightness)

        // Semantic colors
        self.success = Color.hsl(tuning.successHue, tuning.successSaturation, tuning.successLightness)
        self.warning = Color.hsl(tuning.warningHue, tuning.warningSaturation, tuning.warningLightness)
        self.error = Color.hsl(tuning.errorHue, tuning.errorSaturation, tuning.errorLightness)
        self.info = Color.hsl(tuning.infoHue, tuning.infoSaturation, tuning.infoLightness)

        // UI elements
        self.border = Color.hsl(hue, tuning.borderSaturation, tuning.borderLightness)
        self.focusBackground = Color.hsl(tuning.fgHue, tuning.fgTerSaturation, tuning.focusBgLightness)
        self.cursorColor = Color.hsl(tuning.cursorHue, tuning.cursorSaturation, tuning.cursorLightness)
    }
}

// MARK: - Tuning Data

private extension SystemPalette {
    /// Hand-tuned HSL parameters for each preset.
    struct Tuning {
        // Base
        let baseHue: Double
        let bgSaturation: Double
        let barSaturation: Double

        // Foreground
        let fgHue: Double
        let fgSaturation: Double
        let fgLightness: Double
        let fgSecSaturation: Double
        let fgSecLightness: Double
        let fgTerSaturation: Double
        let fgTerLightness: Double
        let fgQuatSaturation: Double
        let fgQuatLightness: Double

        // Accent
        let accentHue: Double
        let accentSaturation: Double
        let accentLightness: Double

        // Semantic
        let successHue: Double
        let successSaturation: Double
        let successLightness: Double
        let warningHue: Double
        let warningSaturation: Double
        let warningLightness: Double
        let errorHue: Double
        let errorSaturation: Double
        let errorLightness: Double
        let infoHue: Double
        let infoSaturation: Double
        let infoLightness: Double

        // Border
        let borderSaturation: Double
        let borderLightness: Double

        // Focus background
        let focusBgLightness: Double

        // Cursor
        let cursorHue: Double
        let cursorSaturation: Double
        let cursorLightness: Double
    }
}

// MARK: - Preset Tuning Values

private extension SystemPalette.Tuning {
    /// Returns the tuning parameters for a given preset.
    static func `for`(_ preset: SystemPalette.Preset) -> SystemPalette.Tuning {
        switch preset {
        case .green:
            SystemPalette.Tuning(
                baseHue: 120, bgSaturation: 30, barSaturation: 35,
                fgHue: 120, fgSaturation: 100, fgLightness: 60,
                fgSecSaturation: 67, fgSecLightness: 46,
                fgTerSaturation: 64, fgTerLightness: 34,
                fgQuatSaturation: 60, fgQuatLightness: 22,
                accentHue: 120, accentSaturation: 100, accentLightness: 70,
                successHue: 120, successSaturation: 100, successLightness: 60,
                warningHue: wrapHue(120 - 45), warningSaturation: 100, warningLightness: 60,
                errorHue: wrapHue(120 - 105), errorSaturation: 100, errorLightness: 60,
                infoHue: wrapHue(120 + 45), infoSaturation: 100, infoLightness: 60,
                borderSaturation: 60, borderLightness: 26,
                focusBgLightness: 15,
                cursorHue: 120, cursorSaturation: 100, cursorLightness: 70
            )

        case .amber:
            SystemPalette.Tuning(
                baseHue: 40, bgSaturation: 30, barSaturation: 35,
                fgHue: 40, fgSaturation: 100, fgLightness: 50,
                fgSecSaturation: 100, fgSecLightness: 40,
                fgTerSaturation: 100, fgTerLightness: 28,
                fgQuatSaturation: 100, fgQuatLightness: 18,
                accentHue: 45, accentSaturation: 100, accentLightness: 60,
                successHue: wrapHue(40 + 40), successSaturation: 100, successLightness: 60,
                warningHue: wrapHue(40 + 20), warningSaturation: 100, warningLightness: 70,
                errorHue: wrapHue(40 - 25), errorSaturation: 100, errorLightness: 60,
                infoHue: wrapHue(40 + 10), infoSaturation: 100, infoLightness: 70,
                borderSaturation: 100, borderLightness: 26,
                focusBgLightness: 12,
                cursorHue: 45, cursorSaturation: 100, cursorLightness: 60
            )

        case .red:
            SystemPalette.Tuning(
                baseHue: 0, bgSaturation: 30, barSaturation: 35,
                fgHue: 0, fgSaturation: 100, fgLightness: 63,
                fgSecSaturation: 60, fgSecLightness: 50,
                fgTerSaturation: 62, fgTerLightness: 35,
                fgQuatSaturation: 60, fgQuatLightness: 22,
                accentHue: 0, accentSaturation: 100, accentLightness: 70,
                successHue: wrapHue(0 + 30), successSaturation: 100, successLightness: 75,
                warningHue: wrapHue(0 + 30), warningSaturation: 100, warningLightness: 70,
                errorHue: 0, errorSaturation: 0, errorLightness: 100,
                infoHue: 0, infoSaturation: 100, infoLightness: 80,
                borderSaturation: 60, borderLightness: 26,
                focusBgLightness: 15,
                cursorHue: 0, cursorSaturation: 100, cursorLightness: 70
            )

        case .violet:
            SystemPalette.Tuning(
                baseHue: 270, bgSaturation: 30, barSaturation: 35,
                fgHue: 270, fgSaturation: 80, fgLightness: 70,
                fgSecSaturation: 70, fgSecLightness: 55,
                fgTerSaturation: 60, fgTerLightness: 40,
                fgQuatSaturation: 55, fgQuatLightness: 26,
                accentHue: 270, accentSaturation: 85, accentLightness: 78,
                successHue: wrapHue(270 + 120), successSaturation: 70, successLightness: 65,
                warningHue: wrapHue(270 + 60), warningSaturation: 80, warningLightness: 70,
                errorHue: wrapHue(270 + 180), errorSaturation: 85, errorLightness: 65,
                infoHue: wrapHue(270 - 60), infoSaturation: 70, infoLightness: 70,
                borderSaturation: 55, borderLightness: 25,
                focusBgLightness: 18,
                cursorHue: 270, cursorSaturation: 85, cursorLightness: 78
            )

        case .blue:
            SystemPalette.Tuning(
                baseHue: 200, bgSaturation: 30, barSaturation: 35,
                fgHue: 200, fgSaturation: 100, fgLightness: 50,
                fgSecSaturation: 100, fgSecLightness: 40,
                fgTerSaturation: 100, fgTerLightness: 30,
                fgQuatSaturation: 100, fgQuatLightness: 20,
                accentHue: 200, accentSaturation: 100, accentLightness: 60,
                successHue: wrapHue(200 + 10), successSaturation: 100, successLightness: 60,
                warningHue: wrapHue(200 + 20), warningSaturation: 100, warningLightness: 70,
                errorHue: wrapHue(200 - 185), errorSaturation: 100, errorLightness: 60,
                infoHue: wrapHue(200 + 5), infoSaturation: 100, infoLightness: 75,
                borderSaturation: 100, borderLightness: 26,
                focusBgLightness: 13,
                cursorHue: 200, cursorSaturation: 100, cursorLightness: 60
            )

        case .white:
            SystemPalette.Tuning(
                baseHue: 225, bgSaturation: 25, barSaturation: 20,
                fgHue: 0, fgSaturation: 0, fgLightness: 91,
                fgSecSaturation: 0, fgSecLightness: 69,
                fgTerSaturation: 0, fgTerLightness: 47,
                fgQuatSaturation: 0, fgQuatLightness: 32,
                accentHue: 0, accentSaturation: 0, accentLightness: 100,
                successHue: 120, successSaturation: 50, successLightness: 75,
                warningHue: 40, warningSaturation: 60, warningLightness: 75,
                errorHue: 0, errorSaturation: 60, errorLightness: 75,
                infoHue: 210, infoSaturation: 60, infoLightness: 75,
                borderSaturation: 0, borderLightness: 28,
                focusBgLightness: 20,
                cursorHue: 0, cursorSaturation: 0, cursorLightness: 100
            )
        }
    }

    /// Wraps a hue value to the 0–360 range.
    private static func wrapHue(_ hue: Double) -> Double {
        var wrapped = hue.truncatingRemainder(dividingBy: 360)
        if wrapped < 0 { wrapped += 360 }
        return wrapped
    }
}

// MARK: - Convenience Accessors

extension Palette where Self == SystemPalette {
    /// The default palette (green).
    public static var `default`: SystemPalette { SystemPalette(.green) }

    /// Green terminal palette (P1 phosphor).
    public static var green: SystemPalette { SystemPalette(.green) }

    /// Amber terminal palette (P3 phosphor).
    public static var amber: SystemPalette { SystemPalette(.amber) }

    /// Red terminal palette (night-vision).
    public static var red: SystemPalette { SystemPalette(.red) }

    /// Violet terminal palette (retro/sci-fi).
    public static var violet: SystemPalette { SystemPalette(.violet) }

    /// Blue VFD terminal palette.
    public static var blue: SystemPalette { SystemPalette(.blue) }

    /// White terminal palette (P4 phosphor).
    public static var white: SystemPalette { SystemPalette(.white) }
}
