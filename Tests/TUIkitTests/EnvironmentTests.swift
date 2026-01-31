//
//  EnvironmentTests.swift
//  TUIkit
//
//  Tests for EnvironmentValues and EnvironmentModifier.
//

import Testing

@testable import TUIkit

/// Custom environment key for testing.
private struct TestStringKey: EnvironmentKey {
    static let defaultValue: String = "default"
}

/// Another custom key for independence tests.
private struct TestIntKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    fileprivate var testString: String {
        get { self[TestStringKey.self] }
        set { self[TestStringKey.self] = newValue }
    }

    fileprivate var testInt: Int {
        get { self[TestIntKey.self] }
        set { self[TestIntKey.self] = newValue }
    }
}

// MARK: - EnvironmentValues Tests

@Suite("EnvironmentValues Tests")
struct EnvironmentValuesTests {

    @Test("Empty environment returns default values")
    func emptyDefaults() {
        let env = EnvironmentValues()
        #expect(env[TestStringKey.self] == "default")
        #expect(env[TestIntKey.self] == 0)
    }

    @Test("Set and get value via subscript")
    func setAndGet() {
        var env = EnvironmentValues()
        env[TestStringKey.self] = "custom"
        #expect(env[TestStringKey.self] == "custom")
    }

    @Test("Different keys are independent")
    func independentKeys() {
        var env = EnvironmentValues()
        env[TestStringKey.self] = "hello"
        env[TestIntKey.self] = 42
        #expect(env[TestStringKey.self] == "hello")
        #expect(env[TestIntKey.self] == 42)
    }

    @Test("setting() returns new copy with modified value")
    func settingCopy() {
        let original = EnvironmentValues()
        let modified = original.setting(\.testString, to: "changed")
        #expect(modified.testString == "changed")
        #expect(original.testString == "default")  // original unchanged
    }

    @Test("setting() preserves other values")
    func settingPreservesOthers() {
        var env = EnvironmentValues()
        env.testInt = 99
        let modified = env.setting(\.testString, to: "new")
        #expect(modified.testString == "new")
        #expect(modified.testInt == 99)  // preserved
    }
}

// MARK: - EnvironmentModifier Tests

@Suite("EnvironmentModifier Tests")
struct EnvironmentModifierTests {
}
