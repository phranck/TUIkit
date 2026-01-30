//
//  AppearanceTests.swift
//  TUIkit
//
//  Tests for the Appearance system.
//

import Testing

@testable import TUIkit

// MARK: - Appearance Tests

@Suite("Appearance Tests")
struct AppearanceTests {

    // MARK: - Appearance ID Tests

    @Test("Appearance ID can be created with rawValue")
    func appearanceIdRawValue() {
        let id = Appearance.ID(rawValue: "custom")
        #expect(id.rawValue == "custom")
    }

    @Test("Predefined appearance IDs exist")
    func predefinedAppearanceIds() {
        #expect(Appearance.ID.line.rawValue == "line")
        #expect(Appearance.ID.rounded.rawValue == "rounded")
        #expect(Appearance.ID.doubleLine.rawValue == "doubleLine")
        #expect(Appearance.ID.heavy.rawValue == "heavy")
        #expect(Appearance.ID.block.rawValue == "block")
    }

    @Test("Appearance IDs are hashable")
    func appearanceIdHashable() {
        let ids: Set<Appearance.ID> = [.line, .rounded, .doubleLine, .heavy, .block]
        #expect(ids.count == 5)
    }

    // MARK: - Appearance Struct Tests

    @Test("Appearance can be created with ID and borderStyle")
    func appearanceCreation() {
        let appearance = Appearance(id: .line, borderStyle: .line)
        #expect(appearance.rawId == .line)
        #expect(appearance.borderStyle == .line)
    }

    @Test("Appearance name is derived from ID")
    func appearanceName() {
        // .capitalized lowercases after first letter, so "doubleLine" becomes "Doubleline"
        #expect(Appearance.line.name == "Line")
        #expect(Appearance.rounded.name == "Rounded")
        #expect(Appearance.doubleLine.name == "Doubleline")
        #expect(Appearance.heavy.name == "Heavy")
        #expect(Appearance.block.name == "Block")
    }

    @Test("Predefined appearances have correct border styles")
    func predefinedAppearances() {
        #expect(Appearance.line.borderStyle == .line)
        #expect(Appearance.rounded.borderStyle == .rounded)
        #expect(Appearance.doubleLine.borderStyle == .doubleLine)
        #expect(Appearance.heavy.borderStyle == .heavy)
        #expect(Appearance.block.borderStyle == .block)
    }

    @Test("Default appearance is rounded")
    func defaultAppearance() {
        #expect(Appearance.default.rawId == .rounded)
        #expect(Appearance.default.borderStyle == .rounded)
    }

    @Test("Appearances are equatable")
    func appearanceEquatable() {
        let appearance1 = Appearance.line
        let appearance2 = Appearance(id: .line, borderStyle: .line)
        #expect(appearance1 == appearance2)
    }

    // MARK: - Appearance Registry Tests

    @Test("AppearanceRegistry contains all predefined appearances")
    func registryContainsAll() {
        let all = AppearanceRegistry.all
        #expect(all.count == 5)
        #expect(all.contains { $0.rawId == .line })
        #expect(all.contains { $0.rawId == .rounded })
        #expect(all.contains { $0.rawId == .doubleLine })
        #expect(all.contains { $0.rawId == .heavy })
        #expect(all.contains { $0.rawId == .block })
    }

    @Test("AppearanceRegistry cycling order is correct")
    func registryCyclingOrder() {
        let all = AppearanceRegistry.all
        // Order: line → rounded → doubleLine → heavy → block
        #expect(all[0].rawId == .line)
        #expect(all[1].rawId == .rounded)
        #expect(all[2].rawId == .doubleLine)
        #expect(all[3].rawId == .heavy)
        #expect(all[4].rawId == .block)
    }

    @Test("AppearanceRegistry can find appearance by ID")
    func registryFindById() {
        let found = AppearanceRegistry.appearance(withId: .heavy)
        #expect(found != nil)
        #expect(found?.rawId == .heavy)
        #expect(found?.borderStyle == .heavy)
    }

    @Test("AppearanceRegistry returns nil for unknown ID")
    func registryUnknownId() {
        let customId = Appearance.ID(rawValue: "unknown")
        let found = AppearanceRegistry.appearance(withId: customId)
        #expect(found == nil)
    }

    // MARK: - Cyclable Conformance

    @Test("Appearance conforms to Cyclable with string id")
    func cyclableConformance() {
        let appearance = Appearance.rounded
        let cyclable: any Cyclable = appearance
        #expect(cyclable.id == "rounded")
        #expect(cyclable.name == "Rounded")
    }
}

// MARK: - Appearance Manager Tests (ThemeManager)

@Suite("Appearance Manager Tests")
struct AppearanceManagerTests {

    /// Creates a ThemeManager for appearances (test helper).
    private func makeAppearanceManager(items: [Appearance] = AppearanceRegistry.all) -> ThemeManager {
        ThemeManager(items: items, applyToEnvironment: { _ in })
    }

    @Test("ThemeManager for appearances can be instantiated")
    func managerCreation() {
        let manager = makeAppearanceManager()
        #expect(manager.items.count == 5)
    }

    @Test("ThemeManager for appearances starts with first appearance (line)")
    func managerStartsWithLine() {
        let manager = makeAppearanceManager()
        #expect(manager.currentAppearance?.rawId == .line)
    }

    @Test("ThemeManager for appearances currentName returns capitalized name")
    func managerCurrentName() {
        let manager = makeAppearanceManager()
        #expect(manager.currentName == "Line")
    }

    @Test("ThemeManager for appearances can be created with custom items")
    func managerCustomAppearances() {
        let custom: [Appearance] = [.rounded, .heavy]
        let manager = makeAppearanceManager(items: custom)
        #expect(manager.items.count == 2)
        #expect(manager.currentAppearance?.rawId == .rounded)
    }
}

// MARK: - Appearance Environment Tests

@Suite("Appearance Environment Tests")
struct AppearanceEnvironmentTests {

    @Test("Appearance can be accessed via environment")
    func environmentAccess() {
        let env = EnvironmentValues()
        #expect(env.appearance.rawId == .rounded)  // Default
    }

    @Test("Appearance can be set via environment")
    func environmentSet() {
        var env = EnvironmentValues()
        env.appearance = .heavy
        #expect(env.appearance.rawId == .heavy)
    }

    @Test("AppearanceManager can be accessed via environment")
    func managerEnvironmentAccess() {
        let env = EnvironmentValues()
        let manager = env.appearanceManager
        #expect(manager.items.count == 5)
    }

    @Test("Custom AppearanceManager can be set via environment")
    func managerEnvironmentSet() {
        var env = EnvironmentValues()
        let customManager = ThemeManager(
            items: [Appearance.line, Appearance.block] as [Appearance],
            applyToEnvironment: { _ in }
        )
        env.appearanceManager = customManager
        #expect(env.appearanceManager.items.count == 2)
    }
}
