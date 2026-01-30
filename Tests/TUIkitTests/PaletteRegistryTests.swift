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
        // Green, Gen. Green, Amber, White, Red, NCurses, Violet = 7
        #expect(PaletteRegistry.all.count == 7)
    }

    @Test("Registry cycling order starts with green")
    func registryCyclingOrder() {
        #expect(PaletteRegistry.all[0].id == "green-phosphor")
        #expect(PaletteRegistry.all[1].id == "generated-gen. green")
        #expect(PaletteRegistry.all[2].id == "amber-phosphor")
        #expect(PaletteRegistry.all[3].id == "white-phosphor")
        #expect(PaletteRegistry.all[4].id == "red-phosphor")
        #expect(PaletteRegistry.all[5].id == "ncurses")
        #expect(PaletteRegistry.all[6].id == "generated-violet")
    }

    @Test("Registry finds palette by ID")
    func findById() {
        let palette = PaletteRegistry.palette(withId: "amber-phosphor")
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
        #expect(palette?.id == "red-phosphor")
    }

    @Test("Registry returns nil for unknown name")
    func unknownName() {
        let palette = PaletteRegistry.palette(withName: "Nonexistent")
        #expect(palette == nil)
    }
}
