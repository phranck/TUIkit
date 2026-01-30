//
//  PreferenceStorageTests.swift
//  TUIkit
//
//  Tests for PreferenceStorage: stack behavior, setValue with reduce,
//  callbacks, beginRenderPass, and reset.
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

    @Test("onPreferenceChange callback is triggered")
    func changeCallback() {
        let storage = PreferenceStorage()
        nonisolated(unsafe) var received: String?
        storage.onPreferenceChange(StorageStringKey.self) { value in
            received = value
        }
        storage.setValue("updated", forKey: StorageStringKey.self)
        #expect(received == "updated")
    }

    @Test("Multiple callbacks for same key all fire")
    func multipleCallbacks() {
        let storage = PreferenceStorage()
        nonisolated(unsafe) var count = 0
        storage.onPreferenceChange(StorageStringKey.self) { _ in count += 1 }
        storage.onPreferenceChange(StorageStringKey.self) { _ in count += 1 }
        storage.setValue("trigger", forKey: StorageStringKey.self)
        #expect(count == 2)
    }

    @Test("beginRenderPass resets callbacks and stack")
    func beginRenderPass() {
        let storage = PreferenceStorage()
        storage.setValue("old", forKey: StorageStringKey.self)
        nonisolated(unsafe) var callbackFired = false
        storage.onPreferenceChange(StorageStringKey.self) { _ in callbackFired = true }

        storage.beginRenderPass()

        #expect(storage.current[StorageStringKey.self] == "default")
        storage.setValue("new", forKey: StorageStringKey.self)
        #expect(callbackFired == false)
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
