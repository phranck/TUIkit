//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ShortcutTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Shortcut Constants Tests

@MainActor
@Suite("Shortcut Constants Tests")
struct ShortcutTests {

    @Test("Combine helper joins shortcuts")
    func combineHelper() {
        let result = Shortcut.combine(Shortcut.control, "c")
        #expect(result == "⌃c")

        let withSeparator = Shortcut.combine("A", "B", "C", separator: "-")
        #expect(withSeparator == "A-B-C")
    }

    @Test("Ctrl helper creates prefix")
    func ctrlHelper() {
        let result = Shortcut.ctrl("c")
        #expect(result == "^c")

        let result2 = Shortcut.ctrl("x")
        #expect(result2 == "^x")
    }

    @Test("Range helper creates range string")
    func rangeHelper() {
        let result = Shortcut.range("1", "9")
        #expect(result == "1-9")

        let result2 = Shortcut.range("a", "z")
        #expect(result2 == "a-z")
    }
}
