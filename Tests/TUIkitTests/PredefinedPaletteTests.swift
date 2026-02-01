//
//  PredefinedPaletteTests.swift
//  TUIkit
//
//  Tests for all predefined palette structs: Green, Amber, Red, Violet, Blue, White.
//

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

    @Test("Green palette block surfaces get progressively brighter")
    func greenBlockSurfaceLuminanceOrder() throws {
        let palette = GreenPalette()
        let bgLum = try #require(relativeLuminance(of: palette.background))
        let headerLum = try #require(relativeLuminance(of: palette.surfaceHeaderBackground))
        let surfaceLum = try #require(relativeLuminance(of: palette.surfaceBackground))
        let elevatedLum = try #require(relativeLuminance(of: palette.elevatedBackground))

        #expect(bgLum < headerLum, "background should be darker than surfaceHeaderBackground")
        #expect(bgLum < surfaceLum, "background should be darker than surfaceBackground")
        #expect(elevatedLum > headerLum, "elevatedBackground should be brighter than surfaceHeaderBackground")
    }

    @Test("Green palette foregrounds get progressively dimmer")
    func greenForegroundLuminanceOrder() throws {
        let palette = GreenPalette()
        let fgLum = try #require(relativeLuminance(of: palette.foreground))
        let fgSecLum = try #require(relativeLuminance(of: palette.foregroundSecondary))
        let fgTerLum = try #require(relativeLuminance(of: palette.foregroundTertiary))

        #expect(fgLum > fgSecLum, "foreground should be brighter than foregroundSecondary")
        #expect(fgSecLum > fgTerLum, "foregroundSecondary should be brighter than foregroundTertiary")
    }

}



// MARK: - Violet Palette Tests

@Suite("Violet Palette Tests")
struct VioletPaletteTests {

    @Test("Violet palette block surfaces get progressively brighter")
    func violetBlockSurfaceLuminanceOrder() throws {
        let palette = VioletPalette()
        let bgLum = try #require(relativeLuminance(of: palette.background))
        let headerLum = try #require(relativeLuminance(of: palette.surfaceHeaderBackground))
        let surfaceLum = try #require(relativeLuminance(of: palette.surfaceBackground))
        let elevatedLum = try #require(relativeLuminance(of: palette.elevatedBackground))

        #expect(bgLum < headerLum, "background should be darker than surfaceHeaderBackground")
        #expect(bgLum < surfaceLum, "background should be darker than surfaceBackground")
        #expect(elevatedLum > headerLum, "elevatedBackground should be brighter than surfaceHeaderBackground")
    }

}

// MARK: - Blue Palette Tests

@Suite("Blue Palette Tests")
struct BluePaletteTests {

    @Test("Blue palette block surfaces get progressively brighter")
    func blueBlockSurfaceLuminanceOrder() throws {
        let palette = BluePalette()
        let bgLum = try #require(relativeLuminance(of: palette.background))
        let headerLum = try #require(relativeLuminance(of: palette.surfaceHeaderBackground))
        let surfaceLum = try #require(relativeLuminance(of: palette.surfaceBackground))
        let elevatedLum = try #require(relativeLuminance(of: palette.elevatedBackground))

        #expect(bgLum < headerLum, "background should be darker than surfaceHeaderBackground")
        #expect(bgLum < surfaceLum, "background should be darker than surfaceBackground")
        #expect(elevatedLum > headerLum, "elevatedBackground should be brighter than surfaceHeaderBackground")
    }

}
