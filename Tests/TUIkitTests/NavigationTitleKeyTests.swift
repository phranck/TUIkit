//  🖥️ TUIKit — Terminal UI Kit for Swift
//  NavigationTitleKeyTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("NavigationTitleKey Tests")
struct NavigationTitleKeyTests {

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
