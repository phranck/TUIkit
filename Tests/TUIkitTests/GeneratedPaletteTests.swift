//
//  GeneratedPaletteTests.swift
//  TUIkit
//
//  Tests for GeneratedPalette: hue-based palette generation.
//

import Testing

@testable import TUIkit

@Suite("Generated Palette Tests")
struct GeneratedPaletteTests {

    @Test("Generated palette creates ID from name")
    func generatedId() {
        let palette = GeneratedPalette(name: "Violet", hue: 270)
        #expect(palette.id == "generated-violet")
        #expect(palette.name == "Violet")
    }

    @Test("Generated palette with different hues produces different colors")
    func differentHues() {
        let green = GeneratedPalette(name: "Green", hue: 120)
        let violet = GeneratedPalette(name: "Violet", hue: 270)
        #expect(green.foreground != violet.foreground)
        #expect(green.accent != violet.accent)
    }

    @Test("Generated palette clamps saturation to 0-100")
    func saturationClamping() {
        // Should not crash with out-of-range values
        let oversaturated = GeneratedPalette(name: "Over", hue: 120, saturation: 200)
        let undersaturated = GeneratedPalette(name: "Under", hue: 120, saturation: -50)
        #expect(oversaturated.foreground != undersaturated.foreground)
    }

    @Test("Generated palette preset hue constants")
    func presetHues() {
        #expect(GeneratedPalette.Hue.green == 120)
        #expect(GeneratedPalette.Hue.violet == 270)
    }

    @Test("Generated palette presets exist")
    func presets() {
        let green = GeneratedPalette.green
        #expect(green.name == "Gen. Green")
        #expect(green.id == "generated-gen. green")

        let violet = GeneratedPalette.violet
        #expect(violet.name == "Violet")
        #expect(violet.id == "generated-violet")
    }

    @Test("Generated palette has distinct background hierarchy")
    func generatedBackgrounds() {
        let palette = GeneratedPalette(name: "Test", hue: 180)
        #expect(palette.background != palette.backgroundSecondary)
        #expect(palette.backgroundSecondary != palette.backgroundTertiary)
    }

    @Test("Generated palette conforms to Sendable")
    func generatedIsSendable() {
        let palette: any Sendable = GeneratedPalette(name: "Test", hue: 90)
        #expect(palette is GeneratedPalette)
    }
}
