//
//  PaletteDefaultTests.swift
//  TUIkit
//
//  Tests for Palette protocol default implementations.
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

@Suite("Palette Default Implementation Tests")
struct PaletteDefaultTests {

    @Test("Defaults derive containerBodyBackground from background")
    func defaultContainerBodyBackground() {
        let palette = MinimalPalette()
        #expect(palette.containerBodyBackground == palette.background)
    }

    @Test("Defaults derive containerCapBackground from background")
    func defaultContainerCapBackground() {
        let palette = MinimalPalette()
        #expect(palette.containerCapBackground == palette.background)
    }

    @Test("Defaults derive foregroundSecondary from foreground")
    func defaultForegroundSecondary() {
        let palette = MinimalPalette()
        #expect(palette.foregroundSecondary == palette.foreground)
    }

    @Test("Defaults derive foregroundPlaceholder from foregroundTertiary")
    func defaultForegroundPlaceholder() {
        let palette = MinimalPalette()
        #expect(palette.foregroundPlaceholder == palette.foregroundTertiary)
    }

    @Test("Defaults derive accentSecondary from accent")
    func defaultAccentSecondary() {
        let palette = MinimalPalette()
        #expect(palette.accentSecondary == palette.accent)
    }

    @Test("Defaults derive statusBarBackground from background")
    func defaultStatusBarBackground() {
        let palette = MinimalPalette()
        #expect(palette.statusBarBackground == palette.background)
    }

    @Test("Defaults derive container and button backgrounds")
    func defaultContainerColors() {
        let palette = MinimalPalette()
        #expect(palette.buttonBackground == palette.containerCapBackground)
        #expect(palette.appHeaderBackground == palette.containerCapBackground)
        #expect(palette.overlayBackground == palette.background)
    }
}
