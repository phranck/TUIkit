//
//  PaletteRegistryTests.swift
//  TUIkit
//
//  Tests for PaletteRegistry: palette lookup and cycling order.
//

import Testing

@testable import TUIkit

@Suite("Palette Registry Tests")
struct PaletteRegistryTests {

    @Test("Registry contains all predefined palettes")
    func registryCount() {
        // Green, Amber, Red, Violet, Blue, White = 6
        #expect(PaletteRegistry.all.count == 6)
    }

    @Test("Registry cycling order follows color spectrum")
    func registryCyclingOrder() {
        #expect(PaletteRegistry.all[0].id == "green")
        #expect(PaletteRegistry.all[1].id == "amber")
        #expect(PaletteRegistry.all[2].id == "red")
        #expect(PaletteRegistry.all[3].id == "violet")
        #expect(PaletteRegistry.all[4].id == "blue")
        #expect(PaletteRegistry.all[5].id == "white")
    }

    @Test("Registry finds palette by ID")
    func findById() {
        let palette = PaletteRegistry.palette(withId: "amber")
        #expect(palette != nil)
        #expect(palette?.name == "Amber")
    }

    @Test("Registry returns nil for unknown ID")
    func unknownId() {
        let palette = PaletteRegistry.palette(withId: "nonexistent")
        #expect(palette == nil)
    }

    @Test("Registry finds palette by name")
    func findByName() {
        let palette = PaletteRegistry.palette(withName: "Red")
        #expect(palette != nil)
        #expect(palette?.id == "red")
    }

    @Test("Registry returns nil for unknown name")
    func unknownName() {
        let palette = PaletteRegistry.palette(withName: "Nonexistent")
        #expect(palette == nil)
    }
}
