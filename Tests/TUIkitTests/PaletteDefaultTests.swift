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

    @Test("Defaults derive backgroundSecondary from background")
    func defaultBackgroundSecondary() {
        let palette = MinimalPalette()
        #expect(palette.backgroundSecondary == palette.background)
    }

    @Test("Defaults derive backgroundTertiary from background")
    func defaultBackgroundTertiary() {
        let palette = MinimalPalette()
        #expect(palette.backgroundTertiary == palette.background)
    }

    @Test("Defaults derive foregroundSecondary from foreground")
    func defaultForegroundSecondary() {
        let palette = MinimalPalette()
        #expect(palette.foregroundSecondary == palette.foreground)
    }

    @Test("Defaults derive accentSecondary from accent")
    func defaultAccentSecondary() {
        let palette = MinimalPalette()
        #expect(palette.accentSecondary == palette.accent)
    }

    @Test("Defaults derive borderFocused from accent")
    func defaultBorderFocused() {
        let palette = MinimalPalette()
        #expect(palette.borderFocused == palette.accent)
    }

    @Test("Defaults derive separator from border")
    func defaultSeparator() {
        let palette = MinimalPalette()
        #expect(palette.separator == palette.border)
    }

    @Test("Defaults derive selection from accent")
    func defaultSelection() {
        let palette = MinimalPalette()
        #expect(palette.selection == palette.accent)
    }

    @Test("Defaults derive selectionBackground from backgroundSecondary")
    func defaultSelectionBackground() {
        let palette = MinimalPalette()
        #expect(palette.selectionBackground == palette.backgroundSecondary)
    }

    @Test("Defaults derive disabled from foregroundTertiary")
    func defaultDisabled() {
        let palette = MinimalPalette()
        #expect(palette.disabled == palette.foregroundTertiary)
    }

    @Test("Defaults derive statusBar colors")
    func defaultStatusBar() {
        let palette = MinimalPalette()
        #expect(palette.statusBarBackground == palette.backgroundSecondary)
        #expect(palette.statusBarForeground == palette.foreground)
        #expect(palette.statusBarHighlight == palette.accent)
    }

    @Test("Defaults derive container colors")
    func defaultContainer() {
        let palette = MinimalPalette()
        #expect(palette.containerBackground == palette.backgroundSecondary)
        #expect(palette.containerHeaderBackground == palette.backgroundTertiary)
        #expect(palette.buttonBackground == palette.backgroundSecondary)
    }
}
