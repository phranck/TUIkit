//
//  AppearanceTests.swift
//  TUIKit
//
//  Tests for the Appearance system.
//

import Testing
@testable import TUIKit

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
        #expect(appearance.id == .line)
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
        #expect(Appearance.default.id == .rounded)
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
        #expect(all.contains { $0.id == .line })
        #expect(all.contains { $0.id == .rounded })
        #expect(all.contains { $0.id == .doubleLine })
        #expect(all.contains { $0.id == .heavy })
        #expect(all.contains { $0.id == .block })
    }
    
    @Test("AppearanceRegistry cycling order is correct")
    func registryCyclingOrder() {
        let all = AppearanceRegistry.all
        // Order: line → rounded → doubleLine → heavy → block
        #expect(all[0].id == .line)
        #expect(all[1].id == .rounded)
        #expect(all[2].id == .doubleLine)
        #expect(all[3].id == .heavy)
        #expect(all[4].id == .block)
    }
    
    @Test("AppearanceRegistry can find appearance by ID")
    func registryFindById() {
        let found = AppearanceRegistry.appearance(withId: .heavy)
        #expect(found != nil)
        #expect(found?.id == .heavy)
        #expect(found?.borderStyle == .heavy)
    }
    
    @Test("AppearanceRegistry returns nil for unknown ID")
    func registryUnknownId() {
        let customId = Appearance.ID(rawValue: "unknown")
        let found = AppearanceRegistry.appearance(withId: customId)
        #expect(found == nil)
    }
}

// MARK: - Appearance Manager Tests

@Suite("Appearance Manager Tests")
struct AppearanceManagerTests {
    
    @Test("AppearanceManager can be instantiated")
    func managerCreation() {
        let manager = AppearanceManager()
        #expect(manager.availableAppearances.count == 5)
    }
    
    @Test("AppearanceManager starts with first appearance (line)")
    func managerStartsWithLine() {
        let manager = AppearanceManager()
        // Default starts at index 0 which is .line
        #expect(manager.currentAppearance.id == .line)
    }
    
    @Test("AppearanceManager currentAppearanceName returns capitalized name")
    func managerCurrentName() {
        let manager = AppearanceManager()
        #expect(manager.currentAppearanceName == "Line")
    }
    
    @Test("AppearanceManager can be created with custom appearances")
    func managerCustomAppearances() {
        let custom = [Appearance.rounded, Appearance.heavy]
        let manager = AppearanceManager(appearances: custom)
        #expect(manager.availableAppearances.count == 2)
        #expect(manager.currentAppearance.id == .rounded)
    }
    
    @Test("AppearanceManager with empty array uses defaults")
    func managerEmptyArray() {
        let manager = AppearanceManager(appearances: [])
        #expect(manager.availableAppearances.count == 5)
    }
}

// MARK: - Appearance Environment Tests

@Suite("Appearance Environment Tests")
struct AppearanceEnvironmentTests {
    
    @Test("Appearance can be accessed via environment")
    func environmentAccess() {
        let env = EnvironmentValues()
        #expect(env.appearance.id == .rounded) // Default
    }
    
    @Test("Appearance can be set via environment")
    func environmentSet() {
        var env = EnvironmentValues()
        env.appearance = .heavy
        #expect(env.appearance.id == .heavy)
    }
    
    @Test("AppearanceManager can be accessed via environment")
    func managerEnvironmentAccess() {
        let env = EnvironmentValues()
        let manager = env.appearanceManager
        #expect(manager.availableAppearances.count == 5)
    }
    
    @Test("Custom AppearanceManager can be set via environment")
    func managerEnvironmentSet() {
        var env = EnvironmentValues()
        let customManager = AppearanceManager(appearances: [.line, .block])
        env.appearanceManager = customManager
        #expect(env.appearanceManager.availableAppearances.count == 2)
    }
}
