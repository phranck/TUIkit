//
//  PaletteDefaultTests.swift
//  TUIkit
//
//  Tests for Palette and BlockPalette protocol default implementations.
//

import Testing

@testable import TUIkit

/// Minimal palette that only provides required properties,
/// so all defaults come from the protocol extension.
private struct MinimalPalette: Palette {
    let id = "minimal"
    let name = "Minimal"
    let background = Color.black
    let foreground = Color.white
    let accent = Color.cyan
    let success = Color.green
    let warning = Color.yellow
    let error = Color.red
    let info = Color.blue
    let border = Color.brightBlack
}

/// Minimal block palette that inherits Palette requirements
/// and uses computed BlockPalette defaults.
private struct MinimalBlockPalette: BlockPalette {
    let id = "minimal-block"
    let name = "Minimal Block"
    let background = Color.hex(0x0A0A0A)
    let foreground = Color.white
    let accent = Color.cyan
    let success = Color.green
    let warning = Color.yellow
    let error = Color.red
    let info = Color.blue
    let border = Color.brightBlack
}

@Suite("Palette Default Implementation Tests")
struct PaletteDefaultTests {

    @Test("Defaults derive foregroundSecondary from foreground")
    func defaultForegroundSecondary() {
        let palette = MinimalPalette()
        #expect(palette.foregroundSecondary == palette.foreground)
    }

    @Test("Defaults derive foregroundTertiary from foreground")
    func defaultForegroundTertiary() {
        let palette = MinimalPalette()
        #expect(palette.foregroundTertiary == palette.foreground)
    }

    @Test("Defaults derive statusBarBackground from background")
    func defaultStatusBarBackground() {
        let palette = MinimalPalette()
        #expect(palette.statusBarBackground == palette.background)
    }

    @Test("Defaults derive appHeaderBackground from background")
    func defaultAppHeaderBackground() {
        let palette = MinimalPalette()
        #expect(palette.appHeaderBackground == palette.background)
    }

    @Test("Defaults derive overlayBackground from background")
    func defaultOverlayBackground() {
        let palette = MinimalPalette()
        #expect(palette.overlayBackground == palette.background)
    }
}

@Suite("BlockPalette Default Implementation Tests")
struct BlockPaletteDefaultTests {

    @Test("BlockPalette surfaceBackground is lighter than background")
    func surfaceBackgroundIsLighter() {
        let palette = MinimalBlockPalette()
        let bgComponents = palette.background.rgbComponents!
        let surfaceComponents = palette.surfaceBackground.rgbComponents!
        let bgBrightness = Int(bgComponents.red) + Int(bgComponents.green) + Int(bgComponents.blue)
        let surfaceBrightness = Int(surfaceComponents.red) + Int(surfaceComponents.green) + Int(surfaceComponents.blue)
        #expect(surfaceBrightness > bgBrightness, "surfaceBackground should be brighter than background")
    }

    @Test("BlockPalette surfaceHeaderBackground is lighter than background")
    func surfaceHeaderBackgroundIsLighter() {
        let palette = MinimalBlockPalette()
        let bgComponents = palette.background.rgbComponents!
        let headerComponents = palette.surfaceHeaderBackground.rgbComponents!
        let bgBrightness = Int(bgComponents.red) + Int(bgComponents.green) + Int(bgComponents.blue)
        let headerBrightness = Int(headerComponents.red) + Int(headerComponents.green) + Int(headerComponents.blue)
        #expect(headerBrightness > bgBrightness, "surfaceHeaderBackground should be brighter than background")
    }

    @Test("BlockPalette elevatedBackground is lighter than surfaceHeaderBackground")
    func elevatedBackgroundIsLighter() {
        let palette = MinimalBlockPalette()
        let headerComponents = palette.surfaceHeaderBackground.rgbComponents!
        let elevatedComponents = palette.elevatedBackground.rgbComponents!
        let headerBrightness = Int(headerComponents.red) + Int(headerComponents.green) + Int(headerComponents.blue)
        let elevatedBrightness = Int(elevatedComponents.red) + Int(elevatedComponents.green) + Int(elevatedComponents.blue)
        #expect(elevatedBrightness > headerBrightness, "elevatedBackground should be brighter than surfaceHeaderBackground")
    }

    @Test("Non-BlockPalette falls back to background via convenience accessors")
    func nonBlockPaletteFallback() {
        let palette = MinimalPalette()
        #expect(palette.blockSurfaceBackground == palette.background)
        #expect(palette.blockSurfaceHeaderBackground == palette.background)
        #expect(palette.blockElevatedBackground == palette.background)
    }
}
