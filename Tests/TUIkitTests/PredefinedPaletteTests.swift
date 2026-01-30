//
//  PredefinedPaletteTests.swift
//  TUIkit
//
//  Tests for all predefined palette structs: Green, Amber, White, Red, NCurses.
//

import Testing

@testable import TUIkit

// MARK: - Green Palette Tests

@Suite("Green Palette Tests")
struct GreenPaletteTests {

    @Test("Green palette has correct identity")
    func greenIdentity() {
        let palette = GreenPalette()
        #expect(palette.id == "green")
        #expect(palette.name == "Green")
    }

    @Test("Green palette has distinct background hierarchy")
    func greenBackgrounds() {
        let palette = GreenPalette()
        #expect(palette.background != palette.backgroundSecondary)
        #expect(palette.backgroundSecondary != palette.backgroundTertiary)
        #expect(palette.background != palette.backgroundTertiary)
    }

    @Test("Green palette has distinct foreground hierarchy")
    func greenForegrounds() {
        let palette = GreenPalette()
        #expect(palette.foreground != palette.foregroundSecondary)
        #expect(palette.foregroundSecondary != palette.foregroundTertiary)
    }

    @Test("Green palette has distinct accent colors")
    func greenAccents() {
        let palette = GreenPalette()
        #expect(palette.accent != palette.accentSecondary)
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

// MARK: - NCurses Palette Tests

@Suite("NCurses Palette Tests")
struct NCursesPaletteTests {

    @Test("NCurses palette has correct identity")
    func ncursesIdentity() {
        let palette = NCursesPalette()
        #expect(palette.id == "ncurses")
        #expect(palette.name == "ncurses")
    }

    @Test("NCurses palette uses standard terminal colors")
    func ncursesUsesStandardColors() {
        let palette = NCursesPalette()
        #expect(palette.background == .black)
        #expect(palette.foreground == .white)
        #expect(palette.accent == .cyan)
        #expect(palette.success == .green)
        #expect(palette.warning == .yellow)
        #expect(palette.error == .red)
    }

    @Test("NCurses palette overrides disabled default")
    func ncursesDisabledOverride() {
        let palette = NCursesPalette()
        #expect(palette.disabled == .brightBlack)
    }
}
