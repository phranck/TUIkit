//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PaletteDefaultTests.swift
//
//  Created by LAYERED.work
//  License: MIT

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

@MainActor
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


