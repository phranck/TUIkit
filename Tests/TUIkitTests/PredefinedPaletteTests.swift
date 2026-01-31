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

    @Test("Green palette has correct identity")
    func greenIdentity() {
        let palette = GreenPalette()
        #expect(palette.id == "green")
        #expect(palette.name == "Green")
    }

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

    @Test("Green palette has all semantic colors")
    func greenSemanticColors() {
        let palette = GreenPalette()
        #expect(palette.success != palette.error)
        #expect(palette.warning != palette.info)
    }
}

// MARK: - Amber Palette Tests

@Suite("Amber Palette Tests")
struct AmberPaletteTests {

    @Test("Amber palette has correct identity")
    func amberIdentity() {
        let palette = AmberPalette()
        #expect(palette.id == "amber")
        #expect(palette.name == "Amber")
    }

    @Test("Amber palette colors differ from green palette")
    func amberDiffersFromGreen() {
        let amber = AmberPalette()
        let green = GreenPalette()
        #expect(amber.foreground != green.foreground)
        #expect(amber.accent != green.accent)
    }
}

// MARK: - White Palette Tests

@Suite("White Palette Tests")
struct WhitePaletteTests {

    @Test("White palette has correct identity")
    func whiteIdentity() {
        let palette = WhitePalette()
        #expect(palette.id == "white")
        #expect(palette.name == "White")
    }
}

// MARK: - Red Palette Tests

@Suite("Red Palette Tests")
struct RedPaletteTests {

    @Test("Red palette has correct identity")
    func redIdentity() {
        let palette = RedPalette()
        #expect(palette.id == "red")
        #expect(palette.name == "Red")
    }
}

// MARK: - Violet Palette Tests

@Suite("Violet Palette Tests")
struct VioletPaletteTests {

    @Test("Violet palette has correct identity")
    func violetIdentity() {
        let palette = VioletPalette()
        #expect(palette.id == "violet")
        #expect(palette.name == "Violet")
    }

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

    @Test("Violet palette colors differ from green palette")
    func violetDiffersFromGreen() {
        let violet = VioletPalette()
        let green = GreenPalette()
        #expect(violet.foreground != green.foreground)
        #expect(violet.accent != green.accent)
    }
}

// MARK: - Blue Palette Tests

@Suite("Blue Palette Tests")
struct BluePaletteTests {

    @Test("Blue palette has correct identity")
    func blueIdentity() {
        let palette = BluePalette()
        #expect(palette.id == "blue")
        #expect(palette.name == "Blue")
    }

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

    @Test("Blue palette colors differ from violet palette")
    func blueDiffersFromViolet() {
        let blue = BluePalette()
        let violet = VioletPalette()
        #expect(blue.foreground != violet.foreground)
        #expect(blue.accent != violet.accent)
    }
}
