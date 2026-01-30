//
//  EnvironmentTests.swift
//  TUIkit
//
//  Tests for EnvironmentValues, EnvironmentStorage (push/pop/withEnvironment),
//  Environment property wrapper, and EnvironmentModifier.
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
        #expect(original.testString == "default") // original unchanged
    }

    @Test("setting() preserves other values")
    func settingPreservesOthers() {
        var env = EnvironmentValues()
        env.testInt = 99
        let modified = env.setting(\.testString, to: "new")
        #expect(modified.testString == "new")
        #expect(modified.testInt == 99) // preserved
    }
}

// MARK: - EnvironmentStorage Tests

@Suite("EnvironmentStorage Tests", .serialized)
struct EnvironmentStorageTests {

    @Test("push and pop restore previous environment")
    func pushPop() {
        let storage = EnvironmentStorage.active
        storage.reset()
        let original = storage.environment

        var modified = EnvironmentValues()
        modified[TestStringKey.self] = "pushed"
        storage.push(modified)
        #expect(storage.environment[TestStringKey.self] == "pushed")

        storage.pop()
        #expect(storage.environment[TestStringKey.self] == original[TestStringKey.self])
    }

    @Test("Nested push/pop restores correctly")
    func nestedPushPop() {
        let storage = EnvironmentStorage.active
        storage.reset()

        var first = EnvironmentValues()
        first[TestStringKey.self] = "first"
        storage.push(first)

        var second = EnvironmentValues()
        second[TestStringKey.self] = "second"
        storage.push(second)
        #expect(storage.environment[TestStringKey.self] == "second")

        storage.pop()
        #expect(storage.environment[TestStringKey.self] == "first")

        storage.pop()
    }

    @Test("Pop on empty stack is safe")
    func popEmptyStack() {
        let storage = EnvironmentStorage.active
        storage.reset()
        // Should not crash
        storage.pop()
    }

    @Test("withEnvironment scopes environment correctly")
    func withEnvironment() {
        let storage = EnvironmentStorage.active
        storage.reset()

        var scoped = EnvironmentValues()
        scoped[TestStringKey.self] = "scoped"

        let result = storage.withEnvironment(scoped) {
            storage.environment[TestStringKey.self]
        }
        #expect(result == "scoped")
        #expect(storage.environment[TestStringKey.self] == "default")
    }

    @Test("reset clears all state")
    func reset() {
        let storage = EnvironmentStorage.active
        var modified = EnvironmentValues()
        modified[TestStringKey.self] = "dirty"
        storage.push(modified)

        storage.reset()
        #expect(storage.environment[TestStringKey.self] == "default")
    }
}

// MARK: - Environment Property Wrapper Tests

@Suite("Environment Property Wrapper Tests", .serialized)
struct EnvironmentPropertyWrapperTests {

    @Test("@Environment reads current value from shared storage")
    func readsFromStorage() {
        let storage = EnvironmentStorage.active
        storage.reset()

        var env = storage.environment
        env[TestStringKey.self] = "from-storage"
        storage.environment = env

        let wrapper = Environment(\.testString)
        #expect(wrapper.wrappedValue == "from-storage")

        // Cleanup
        storage.reset()
    }

    @Test("@Environment reflects changes after storage update")
    func reflectsChanges() {
        let storage = EnvironmentStorage.active
        storage.reset()

        let wrapper = Environment(\.testString)
        #expect(wrapper.wrappedValue == "default")

        var env = storage.environment
        env[TestStringKey.self] = "updated"
        storage.environment = env
        #expect(wrapper.wrappedValue == "updated")

        // Cleanup
        storage.reset()
    }
}

// MARK: - EnvironmentModifier Tests

@Suite("EnvironmentModifier Tests")
struct EnvironmentModifierTests {


}
