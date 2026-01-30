//
//  NavigationTitleKeyTests.swift
//  TUIkit
//
//  Tests for the built-in NavigationTitleKey preference.
//

import Testing

@testable import TUIkit

@Suite("NavigationTitleKey Tests")
struct NavigationTitleKeyTests {

    @Test("Default value is empty string")
    func defaultValue() {
        #expect(NavigationTitleKey.defaultValue == "")
    }

    @Test("NavigationTitleKey uses last-value reduce")
    func lastValueReduce() {
        var value = NavigationTitleKey.defaultValue
        NavigationTitleKey.reduce(value: &value) { "First Title" }
        NavigationTitleKey.reduce(value: &value) { "Second Title" }
        #expect(value == "Second Title")
    }

    @Test("NavigationTitleKey works with PreferenceValues")
    func withPreferenceValues() {
        var values = PreferenceValues()
        values[NavigationTitleKey.self] = "My Title"
        #expect(values[NavigationTitleKey.self] == "My Title")
    }
}
