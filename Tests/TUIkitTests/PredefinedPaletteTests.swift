//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PredefinedPaletteTests.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

import Testing

@testable import TUIkit

// MARK: - Test Helpers

/// Extracts relative luminance from an RGB color using the sRGB formula.
///
/// Returns a value between 0.0 (black) and 1.0 (white).
/// Non-RGB colors (ANSI, semantic) return nil.
private func relativeLuminance(of color: Color) -> Double? {
    guard case .rgb(let red, let green, let blue) = color.value else {
        return nil
    }
    let redNorm = Double(red) / 255.0
    let greenNorm = Double(green) / 255.0
    let blueNorm = Double(blue) / 255.0
    return 0.2126 * redNorm + 0.7152 * greenNorm + 0.0722 * blueNorm
}

// MARK: - Green Palette Tests

@Suite("Green Palette Tests")
struct GreenPaletteTests {

    @Test("Green palette foregrounds get progressively dimmer")
    func greenForegroundLuminanceOrder() throws {
        let palette = SystemPalette(.green)
        let fgLum = try #require(relativeLuminance(of: palette.foreground))
        let fgSecLum = try #require(relativeLuminance(of: palette.foregroundSecondary))
        let fgTerLum = try #require(relativeLuminance(of: palette.foregroundTertiary))

        #expect(fgLum > fgSecLum, "foreground should be brighter than foregroundSecondary")
        #expect(fgSecLum > fgTerLum, "foregroundSecondary should be brighter than foregroundTertiary")
    }
}
