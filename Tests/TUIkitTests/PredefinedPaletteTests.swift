//
//  PredefinedPaletteTests.swift
//  TUIkit
//
//  Tests for all predefined palette structs: Green, Amber, White, Red, NCurses.
//

import Testing

@testable import TUIkit

// MARK: - Green Phosphor Palette Tests

@Suite("Green Phosphor Palette Tests")
struct GreenPhosphorPaletteTests {

    @Test("Green palette has correct identity")
    func greenIdentity() {
        let palette = GreenPhosphorPalette()
        #expect(palette.id == "green-phosphor")
        #expect(palette.name == "Green")
    }

    @Test("Green palette has distinct background hierarchy")
    func greenBackgrounds() {
        let palette = GreenPhosphorPalette()
        #expect(palette.background != palette.backgroundSecondary)
        #expect(palette.backgroundSecondary != palette.backgroundTertiary)
        #expect(palette.background != palette.backgroundTertiary)
    }

    @Test("Green palette has distinct foreground hierarchy")
    func greenForegrounds() {
        let palette = GreenPhosphorPalette()
        #expect(palette.foreground != palette.foregroundSecondary)
        #expect(palette.foregroundSecondary != palette.foregroundTertiary)
    }

    @Test("Green palette has distinct accent colors")
    func greenAccents() {
        let palette = GreenPhosphorPalette()
        #expect(palette.accent != palette.accentSecondary)
    }

    @Test("Green palette has all semantic colors")
    func greenSemanticColors() {
        let palette = GreenPhosphorPalette()
        #expect(palette.success != palette.error)
        #expect(palette.warning != palette.info)
    }
}

// MARK: - Amber Phosphor Palette Tests

@Suite("Amber Phosphor Palette Tests")
struct AmberPhosphorPaletteTests {

    @Test("Amber palette has correct identity")
    func amberIdentity() {
        let palette = AmberPhosphorPalette()
        #expect(palette.id == "amber-phosphor")
        #expect(palette.name == "Amber")
    }

    @Test("Amber palette colors differ from green palette")
    func amberDiffersFromGreen() {
        let amber = AmberPhosphorPalette()
        let green = GreenPhosphorPalette()
        #expect(amber.foreground != green.foreground)
        #expect(amber.accent != green.accent)
    }
}

// MARK: - White Phosphor Palette Tests

@Suite("White Phosphor Palette Tests")
struct WhitePhosphorPaletteTests {

    @Test("White palette has correct identity")
    func whiteIdentity() {
        let palette = WhitePhosphorPalette()
        #expect(palette.id == "white-phosphor")
        #expect(palette.name == "White")
    }
}

// MARK: - Red Phosphor Palette Tests

@Suite("Red Phosphor Palette Tests")
struct RedPhosphorPaletteTests {

    @Test("Red palette has correct identity")
    func redIdentity() {
        let palette = RedPhosphorPalette()
        #expect(palette.id == "red-phosphor")
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
