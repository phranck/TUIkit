//
//  FocusTests.swift
//  SwiftTUI
//
//  Tests for the focus management system.
//

import Foundation
import Testing
@testable import SwiftTUI

// MARK: - Mock Focusable

/// A mock focusable element for testing.
final class MockFocusable: Focusable {
    let focusID: String
    var canBeFocused: Bool
    var focusReceivedCount = 0
    var focusLostCount = 0
    var lastKeyEvent: KeyEvent?
    var shouldConsumeEvents: Bool

    init(id: String, canBeFocused: Bool = true, shouldConsumeEvents: Bool = false) {
        self.focusID = id
        self.canBeFocused = canBeFocused
        self.shouldConsumeEvents = shouldConsumeEvents
    }

    func onFocusReceived() {
        focusReceivedCount += 1
    }

    func onFocusLost() {
        focusLostCount += 1
    }

    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        lastKeyEvent = event
        return shouldConsumeEvents
    }
}

// MARK: - Focus Manager Tests

@Suite("Focus Manager Tests")
struct FocusManagerTests {

    @Test("FocusManager is a singleton")
    func focusManagerSingleton() {
        let manager1 = FocusManager.shared
        let manager2 = FocusManager.shared
        #expect(manager1 === manager2)
    }

    @Test("Register focusable element")
    func registerFocusable() {
        let manager = FocusManager.shared
        manager.clear()

        let element = MockFocusable(id: "test-element")
        manager.register(element)

        // First registered element should be auto-focused
        #expect(manager.isFocused(element))
        #expect(manager.currentFocusedID == "test-element")
    }

    @Test("Register multiple elements")
    func registerMultipleElements() {
        let manager = FocusManager.shared
        manager.clear()

        let element1 = MockFocusable(id: "element-1")
        let element2 = MockFocusable(id: "element-2")

        manager.register(element1)
        manager.register(element2)

        // First element should be focused
        #expect(manager.isFocused(element1))
        #expect(!manager.isFocused(element2))
    }

    @Test("Avoid duplicate registration")
    func avoidDuplicates() {
        let manager = FocusManager.shared
        manager.clear()

        let element = MockFocusable(id: "unique-element")
        manager.register(element)
        manager.register(element)

        // Should still work without issues
        #expect(manager.isFocused(element))
    }

    @Test("Unregister focusable element")
    func unregisterFocusable() {
        let manager = FocusManager.shared
        manager.clear()

        let element1 = MockFocusable(id: "elem-1")
        let element2 = MockFocusable(id: "elem-2")

        manager.register(element1)
        manager.register(element2)
        manager.unregister(element1)

        // element2 should now be focused (focusNext called)
        #expect(!manager.isFocused(element1))
    }

    @Test("Clear all focusables")
    func clearAll() {
        let manager = FocusManager.shared
        manager.clear()

        let element = MockFocusable(id: "to-clear")
        manager.register(element)
        manager.clear()

        #expect(manager.currentFocusedID == nil)
        #expect(manager.currentFocused == nil)
    }

    @Test("Focus specific element")
    func focusSpecific() {
        let manager = FocusManager.shared
        manager.clear()

        let element1 = MockFocusable(id: "first")
        let element2 = MockFocusable(id: "second")

        manager.register(element1)
        manager.register(element2)
        manager.focus(element2)

        #expect(manager.isFocused(element2))
        #expect(!manager.isFocused(element1))
    }

    @Test("Focus by ID")
    func focusByID() {
        let manager = FocusManager.shared
        manager.clear()

        let element1 = MockFocusable(id: "id-a")
        let element2 = MockFocusable(id: "id-b")

        manager.register(element1)
        manager.register(element2)
        manager.focus(id: "id-b")

        #expect(manager.isFocused(id: "id-b"))
        #expect(!manager.isFocused(id: "id-a"))
    }

    @Test("Focus next wraps around")
    func focusNextWrapsAround() {
        let manager = FocusManager.shared
        manager.clear()

        let element1 = MockFocusable(id: "nav-1")
        let element2 = MockFocusable(id: "nav-2")
        let element3 = MockFocusable(id: "nav-3")

        manager.register(element1)
        manager.register(element2)
        manager.register(element3)

        // Start at element1
        #expect(manager.isFocused(element1))

        manager.focusNext()
        #expect(manager.isFocused(element2))

        manager.focusNext()
        #expect(manager.isFocused(element3))

        manager.focusNext()  // Should wrap to element1
        #expect(manager.isFocused(element1))
    }

    @Test("Focus previous wraps around")
    func focusPreviousWrapsAround() {
        let manager = FocusManager.shared
        manager.clear()

        let element1 = MockFocusable(id: "prev-1")
        let element2 = MockFocusable(id: "prev-2")
        let element3 = MockFocusable(id: "prev-3")

        manager.register(element1)
        manager.register(element2)
        manager.register(element3)

        // Explicitly start at element1
        manager.focus(element1)
        #expect(manager.isFocused(element1))

        manager.focusPrevious()  // Should wrap to element3
        #expect(manager.isFocused(element3))

        manager.focusPrevious()
        #expect(manager.isFocused(element2))

        manager.focusPrevious()
        #expect(manager.isFocused(element1))
    }

    @Test("Skip non-focusable elements")
    func skipNonFocusable() {
        let manager = FocusManager.shared
        manager.clear()

        let element1 = MockFocusable(id: "focusable-1")
        let element2 = MockFocusable(id: "disabled", canBeFocused: false)
        let element3 = MockFocusable(id: "focusable-2")

        manager.register(element1)
        manager.register(element2)
        manager.register(element3)

        // Start at element1
        manager.focusNext()
        // Should skip element2 and go to element3
        #expect(manager.isFocused(element3))
    }

    @Test("Cannot focus disabled element")
    func cannotFocusDisabled() {
        let manager = FocusManager.shared
        manager.clear()

        let disabled = MockFocusable(id: "disabled", canBeFocused: false)
        manager.register(disabled)

        // Should not be focused
        #expect(!manager.isFocused(disabled))
        #expect(manager.currentFocusedID == nil)
    }

    @Test("Focus callbacks are called")
    func focusCallbacks() {
        let manager = FocusManager.shared
        manager.clear()

        let element1 = MockFocusable(id: "callback-1-\(UUID().uuidString)")
        let element2 = MockFocusable(id: "callback-2-\(UUID().uuidString)")

        // Register element1 - it should be auto-focused since manager was just cleared
        manager.register(element1)
        // Note: focusReceivedCount should be 1 after registration auto-focus
        #expect(element1.focusReceivedCount == 1, "Element1 should receive focus when registered as first element")

        manager.register(element2)
        // Explicitly focus element2
        manager.focus(element2)

        // element1 should have lost focus, element2 should have received it
        #expect(element1.focusLostCount == 1, "Element1 should lose focus when element2 is focused")
        #expect(element2.focusReceivedCount == 1, "Element2 should receive focus when explicitly focused")
    }

    @Test("Tab key moves focus next")
    func tabKeyMovesFocusNext() {
        let manager = FocusManager.shared
        manager.clear()

        let element1 = MockFocusable(id: "tab-1")
        let element2 = MockFocusable(id: "tab-2")

        manager.register(element1)
        manager.register(element2)

        let tabEvent = KeyEvent(key: .tab, ctrl: false, alt: false, shift: false)
        let handled = manager.dispatchKeyEvent(tabEvent)

        #expect(handled)
        #expect(manager.isFocused(element2))
    }

    @Test("Shift+Tab moves focus previous")
    func shiftTabMovesFocusPrevious() {
        let manager = FocusManager.shared
        manager.clear()

        let element1 = MockFocusable(id: "shift-1")
        let element2 = MockFocusable(id: "shift-2")

        manager.register(element1)
        manager.register(element2)
        manager.focus(element2)

        let shiftTabEvent = KeyEvent(key: .tab, ctrl: false, alt: false, shift: true)
        let handled = manager.dispatchKeyEvent(shiftTabEvent)

        #expect(handled)
        #expect(manager.isFocused(element1))
    }

    @Test("Key events dispatched to focused element")
    func keyEventsDispatched() {
        let manager = FocusManager.shared
        manager.clear()

        let element = MockFocusable(id: "dispatch-test", shouldConsumeEvents: true)
        manager.register(element)

        let event = KeyEvent(key: .enter, ctrl: false, alt: false, shift: false)
        let handled = manager.dispatchKeyEvent(event)

        #expect(handled)
        #expect(element.lastKeyEvent?.key == .enter)
    }

    @Test("onFocusChange callback triggered")
    func onFocusChangeCallback() {
        let manager = FocusManager.shared
        manager.clear()

        var callbackCount = 0
        manager.onFocusChange = {
            callbackCount += 1
        }

        let element = MockFocusable(id: "callback-test")
        manager.register(element)

        #expect(callbackCount == 1)

        // Cleanup
        manager.onFocusChange = nil
    }
}

// MARK: - Focus State Tests

@Suite("Focus State Tests")
struct FocusStateTests {

    @Test("FocusState can be created with ID")
    func focusStateCreation() {
        let state = FocusState(id: "my-focus-id")
        #expect(state.id == "my-focus-id")
    }

    @Test("FocusState generates UUID if no ID provided")
    func focusStateGeneratesUUID() {
        let state = FocusState()
        #expect(!state.id.isEmpty)
        // UUID format check
        #expect(state.id.contains("-"))
    }

    @Test("FocusState isFocused reflects manager state")
    func focusStateIsFocused() {
        let manager = FocusManager.shared
        manager.clear()

        let state = FocusState(id: "state-test")
        let element = MockFocusable(id: "state-test")

        manager.register(element)

        // The element is focused, so state should report focused
        #expect(state.isFocused)
    }

    @Test("FocusState requestFocus works")
    func focusStateRequestFocus() {
        let manager = FocusManager.shared
        manager.clear()

        let element1 = MockFocusable(id: "req-1")
        let element2 = MockFocusable(id: "req-2")

        manager.register(element1)
        manager.register(element2)

        let state = FocusState(id: "req-2")
        state.requestFocus()

        #expect(manager.isFocused(id: "req-2"))
    }
}
