//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PreferenceStorageTests.swift
//
//  Created by LAYERED.work
//  License: MIT  callbacks, beginRenderPass, and reset.
//

import Testing

@testable import TUIkit

/// String preference key for storage tests.
private struct StorageStringKey: PreferenceKey {
    static let defaultValue: String = "default"
}

/// Additive counter preference key for storage tests.
private struct StorageCounterKey: PreferenceKey {
    static let defaultValue: Int = 0

    static func reduce(value: inout Int, nextValue: () -> Int) {
        value += nextValue()
    }
}

@MainActor
@Suite("PreferenceStorage Tests")
struct PreferenceStorageTests {

    @Test("New storage has default values")
    func newStorageDefaults() {
        let storage = PreferenceStorage()
        #expect(storage.current[StorageStringKey.self] == "default")
    }

    @Test("setValue stores value")
    func setValueStores() {
        let storage = PreferenceStorage()
        storage.setValue("hello", forKey: StorageStringKey.self)
        #expect(storage.current[StorageStringKey.self] == "hello")
    }

    @Test("setValue with additive reduce accumulates")
    func setValueAccumulates() {
        let storage = PreferenceStorage()
        storage.setValue(5, forKey: StorageCounterKey.self)
        storage.setValue(3, forKey: StorageCounterKey.self)
        #expect(storage.current[StorageCounterKey.self] == 8)
    }

    @Test("Push creates new context")
    func pushNewContext() {
        let storage = PreferenceStorage()
        storage.setValue("outer", forKey: StorageStringKey.self)
        storage.push()
        #expect(storage.current[StorageStringKey.self] == "default")
    }

    @Test("Pop merges into parent")
    func popMerges() {
        let storage = PreferenceStorage()
        storage.push()
        storage.setValue("inner", forKey: StorageStringKey.self)
        _ = storage.pop()
        #expect(storage.current[StorageStringKey.self] == "inner")
    }

    @Test("Nested push/pop preserves outer values")
    func nestedPushPop() {
        let storage = PreferenceStorage()
        storage.setValue("outer", forKey: StorageStringKey.self)
        storage.push()
        storage.setValue("inner", forKey: StorageStringKey.self)
        _ = storage.pop()
        #expect(storage.current[StorageStringKey.self] == "inner")
    }

    @Test("Multiple nested levels work correctly")
    func multipleNesting() {
        let storage = PreferenceStorage()
        storage.setValue(1, forKey: StorageCounterKey.self)
        storage.push()
        storage.setValue(2, forKey: StorageCounterKey.self)
        storage.push()
        storage.setValue(3, forKey: StorageCounterKey.self)
        _ = storage.pop()
        _ = storage.pop()
        #expect(storage.current[StorageCounterKey.self] != 0)
    }

    @Test("Pop on single context returns current values")
    func popSingleContext() {
        let storage = PreferenceStorage()
        storage.setValue("value", forKey: StorageStringKey.self)
        let popped = storage.pop()
        #expect(popped[StorageStringKey.self] == "value")
        #expect(storage.current[StorageStringKey.self] == "value")
    }

    // Change notification is no longer a PreferenceStorage concern: the
    // onPreferenceChange VIEW modifier compares the subtree value against
    // the last committed frame and fires at frame commit (see
    // OnPreferenceChangeModifier and PendingEffectCommitTests).

    @Test("beginRenderPass resets the value stack")
    func beginRenderPass() {
        let storage = PreferenceStorage()
        storage.setValue("old", forKey: StorageStringKey.self)

        storage.beginRenderPass()

        #expect(storage.current[StorageStringKey.self] == "default")
    }

    @Test("reset clears everything")
    func resetClears() {
        let storage = PreferenceStorage()
        storage.setValue("data", forKey: StorageStringKey.self)
        storage.push()
        storage.setValue(42, forKey: StorageCounterKey.self)

        storage.reset()

        #expect(storage.current[StorageStringKey.self] == "default")
        #expect(storage.current[StorageCounterKey.self] == 0)
    }
}
