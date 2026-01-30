//
//  PreferenceValuesTests.swift
//  TUIkit
//
//  Tests for PreferenceValues: subscript access, defaults, and merge behavior.
//

import Testing

@testable import TUIkit

/// String preference key for testing.
private struct ValStringKey: PreferenceKey {
    static let defaultValue: String = "default"
}

/// Counter preference key for testing.
private struct ValCounterKey: PreferenceKey {
    static let defaultValue: Int = 0
}

@Suite("PreferenceValues Tests")
struct PreferenceValuesTests {

    @Test("Empty values return default")
    func emptyDefault() {
        let values = PreferenceValues()
        #expect(values[ValStringKey.self] == "default")
        #expect(values[ValCounterKey.self] == 0)
    }

    @Test("Set and get value")
    func setAndGet() {
        var values = PreferenceValues()
        values[ValStringKey.self] = "custom"
        #expect(values[ValStringKey.self] == "custom")
    }

    @Test("Different keys are independent")
    func independentKeys() {
        var values = PreferenceValues()
        values[ValStringKey.self] = "hello"
        values[ValCounterKey.self] = 42
        #expect(values[ValStringKey.self] == "hello")
        #expect(values[ValCounterKey.self] == 42)
    }

    @Test("Merge overwrites existing values")
    func mergeOverwrites() {
        var base = PreferenceValues()
        base[ValStringKey.self] = "original"

        var other = PreferenceValues()
        other[ValStringKey.self] = "overwritten"

        base.merge(other)
        #expect(base[ValStringKey.self] == "overwritten")
    }

    @Test("Merge preserves non-overlapping values")
    func mergePreservesOthers() {
        var base = PreferenceValues()
        base[ValStringKey.self] = "kept"

        var other = PreferenceValues()
        other[ValCounterKey.self] = 99

        base.merge(other)
        #expect(base[ValStringKey.self] == "kept")
        #expect(base[ValCounterKey.self] == 99)
    }

    @Test("Merge with empty values is no-op")
    func mergeEmpty() {
        var base = PreferenceValues()
        base[ValStringKey.self] = "unchanged"

        base.merge(PreferenceValues())
        #expect(base[ValStringKey.self] == "unchanged")
    }
}
