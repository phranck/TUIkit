//
//  ThemeManagerCyclingTests.swift
//  TUIkit
//
//  Tests for ThemeManager cycling, selection, and typed accessors.
//

import Testing

@testable import TUIkit

@Suite("ThemeManager Cycling Tests")
struct ThemeManagerCyclingTests {

    /// Simple Cyclable item for testing.
    private struct TestItem: Cyclable {
        let id: String
        var name: String { id.capitalized }
    }

    /// Creates a ThemeManager with the given number of TestItems.
    private func makeManager(count: Int = 3) -> ThemeManager {
        let items = (0..<count).map { TestItem(id: "item-\($0)") }
        return ThemeManager(items: items, applyToEnvironment: { _ in })
    }

    @Test("ThemeManager starts at first item")
    func startsAtFirst() {
        let manager = makeManager()
        #expect(manager.current.id == "item-0")
    }

    @Test("cycleNext advances to next item")
    func cycleNextAdvances() {
        let manager = makeManager()
        manager.cycleNext()
        #expect(manager.current.id == "item-1")
    }

    @Test("cycleNext wraps around")
    func cycleNextWraps() {
        let manager = makeManager(count: 3)
        manager.cycleNext()
        manager.cycleNext()
        manager.cycleNext()
        #expect(manager.current.id == "item-0")
    }

    @Test("cyclePrevious goes to previous item")
    func cyclePreviousGoesBack() {
        let manager = makeManager()
        manager.cycleNext()
        manager.cycleNext()
        manager.cyclePrevious()
        #expect(manager.current.id == "item-1")
    }

    @Test("cyclePrevious wraps around to last")
    func cyclePreviousWraps() {
        let manager = makeManager(count: 3)
        manager.cyclePrevious()
        #expect(manager.current.id == "item-2")
    }

    @Test("setCurrent selects item by ID")
    func setCurrentById() {
        let manager = makeManager()
        let target = TestItem(id: "item-2")
        manager.setCurrent(target)
        #expect(manager.current.id == "item-2")
    }

    @Test("setCurrent with unknown ID keeps current")
    func setCurrentUnknownId() {
        let manager = makeManager()
        manager.cycleNext() // now at item-1
        let unknown = TestItem(id: "unknown")
        manager.setCurrent(unknown)
        #expect(manager.current.id == "item-1")
    }

    @Test("currentName returns capitalized name")
    func currentNameCapitalized() {
        let manager = makeManager()
        #expect(manager.currentName == "Item-0")
    }

    @Test("currentPalette returns nil for non-palette items")
    func currentPaletteNilForNonPalette() {
        let manager = makeManager()
        #expect(manager.currentPalette == nil)
    }

    @Test("currentAppearance returns nil for non-appearance items")
    func currentAppearanceNilForNonAppearance() {
        let manager = makeManager()
        #expect(manager.currentAppearance == nil)
    }

    @Test("ThemeManager with palette items returns currentPalette")
    func paletteManagerReturnsPalette() {
        let palettes: [any Cyclable] = [
            GreenPhosphorPalette(),
            AmberPhosphorPalette(),
        ]
        let manager = ThemeManager(items: palettes, applyToEnvironment: { _ in })
        #expect(manager.currentPalette != nil)
        #expect(manager.currentPalette?.id == "green-phosphor")
    }

    @Test("applyToEnvironment closure is called on cycle")
    func applyCalledOnCycle() {
        nonisolated(unsafe) var appliedIds: [String] = []
        let items: [any Cyclable] = [TestItem(id: "a"), TestItem(id: "b")]
        let manager = ThemeManager(items: items) { item in
            appliedIds.append(item.id)
        }
        manager.cycleNext()
        manager.cycleNext()
        #expect(appliedIds == ["b", "a"])
    }
}
