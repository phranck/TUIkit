//  TUIKit - Terminal UI Kit for Swift
//  FocusStateTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

// MARK: - Focus State Tests

@MainActor
@Suite("Focus State Tests", .serialized)
struct FocusStateTests {

    @Test("FocusState isFocused reflects focus manager state")
    func focusStateIsFocused() {
        let manager = FocusManager()
        let state = FocusState(id: "state-test", focusManager: manager)
        let element = MockFocusable(id: "state-test")

        manager.register(element)

        // The element is focused, so state should report focused
        #expect(state.isFocused)
    }

    @Test("FocusState requestFocus changes focus via manager")
    func focusStateRequestFocus() {
        let manager = FocusManager()

        let element1 = MockFocusable(id: "req-1")
        let element2 = MockFocusable(id: "req-2")

        manager.register(element1)
        manager.register(element2)

        // First element is focused after registration
        #expect(manager.isFocused(id: "req-1"))

        // Request focus for second element
        FocusState(id: "req-2", focusManager: manager).requestFocus()
        #expect(manager.isFocused(id: "req-2"), "req-2 should be focused after requestFocus()")
    }
}
