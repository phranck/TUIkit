//
//  PreferenceKeyTests.swift
//  TUIkit
//
//  Tests for PreferenceKey protocol: default reduce and custom reduce implementations.
//

import Testing

@testable import TUIkit

/// A simple string preference key for testing (default reduce = last value).
private struct TestStringKey: PreferenceKey {
    static let defaultValue: String = "default"
}

/// A counter preference key with additive reduce.
private struct TestCounterKey: PreferenceKey {
    static let defaultValue: Int = 0

    static func reduce(value: inout Int, nextValue: () -> Int) {
        value += nextValue()
    }
}

/// An array preference key with append reduce.
private struct TestArrayKey: PreferenceKey {
    static let defaultValue: [String] = []

    static func reduce(value: inout [String], nextValue: () -> [String]) {
        value.append(contentsOf: nextValue())
    }
}

@Suite("PreferenceKey Tests")
struct PreferenceKeyTests {

    @Test("Default reduce uses last value")
    func defaultReduce() {
        var value = TestStringKey.defaultValue
        TestStringKey.reduce(value: &value) { "first" }
        TestStringKey.reduce(value: &value) { "second" }
        #expect(value == "second")
    }

    @Test("Custom additive reduce accumulates")
    func customAdditiveReduce() {
        var value = TestCounterKey.defaultValue
        TestCounterKey.reduce(value: &value) { 5 }
        TestCounterKey.reduce(value: &value) { 3 }
        #expect(value == 8)
    }

    @Test("Custom array reduce appends")
    func customArrayReduce() {
        var value = TestArrayKey.defaultValue
        TestArrayKey.reduce(value: &value) { ["a"] }
        TestArrayKey.reduce(value: &value) { ["b", "c"] }
        #expect(value == ["a", "b", "c"])
    }
}
