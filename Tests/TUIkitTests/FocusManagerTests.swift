//  TUIKit - Terminal UI Kit for Swift
//  FocusManagerTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

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

@MainActor
@Suite("Focus Manager Tests")
struct FocusManagerTests {

    @Test("Register focusable element")
    func registerFocusable() {
        let manager = FocusManager()

        let element = MockFocusable(id: "test-element")
        manager.register(element)

        // First registered element should be auto-focused
        #expect(manager.isFocused(element))
        #expect(manager.currentFocusedID == "test-element")
    }

    @Test("Register multiple elements")
    func registerMultipleElements() {
        let manager = FocusManager()

        let element1 = MockFocusable(id: "element-1")
        let element2 = MockFocusable(id: "element-2")

        manager.register(element1)
        manager.register(element2)

        // First element should be focused
        #expect(manager.isFocused(element1))
        #expect(!manager.isFocused(element2))
    }

    @Test("Unregister focusable element")
    func unregisterFocusable() {
        let manager = FocusManager()

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
        let manager = FocusManager()

        let element = MockFocusable(id: "to-clear")
        manager.register(element)
        manager.clear()

        #expect(manager.currentFocusedID == nil)
        #expect(manager.currentFocused == nil)
    }

    @Test("Focus specific element")
    func focusSpecific() {
        let manager = FocusManager()

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
        let manager = FocusManager()

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
        let manager = FocusManager()

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
        let manager = FocusManager()

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
        let manager = FocusManager()

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
        let manager = FocusManager()

        let disabled = MockFocusable(id: "disabled", canBeFocused: false)
        manager.register(disabled)

        // Should not be focused
        #expect(!manager.isFocused(disabled))
        #expect(manager.currentFocusedID == nil)
    }

    @Test("Focus callbacks are called")
    func focusCallbacks() {
        let manager = FocusManager()

        let element1 = MockFocusable(id: "callback-1")
        let element2 = MockFocusable(id: "callback-2")

        // Register element1 - it should be auto-focused since manager was just created
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
        let manager = FocusManager()

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
        let manager = FocusManager()

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
        let manager = FocusManager()

        let element = MockFocusable(id: "dispatch-test", shouldConsumeEvents: true)
        manager.register(element)

        let event = KeyEvent(key: .enter, ctrl: false, alt: false, shift: false)
        let handled = manager.dispatchKeyEvent(event)

        #expect(handled)
        #expect(element.lastKeyEvent?.key == .enter)
    }

    @Test("onFocusChange callback triggered")
    func onFocusChangeCallback() {
        let manager = FocusManager()

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

// MARK: - Focus Manager Environment Tests

@MainActor
@Suite("Focus Manager Environment Tests")
struct FocusManagerEnvironmentTests {

    @Test("FocusManager is accessible via environment key")
    func focusManagerEnvironmentKey() {
        let manager = FocusManager()
        var environment = EnvironmentValues()
        environment.focusManager = manager

        #expect(environment.focusManager === manager)
    }

    @Test("Multiple tests can have independent FocusManagers")
    func independentManagers() {
        let manager1 = FocusManager()
        let manager2 = FocusManager()

        let element1 = MockFocusable(id: "test-1")
        let element2 = MockFocusable(id: "test-2")

        manager1.register(element1)
        manager2.register(element2)

        // Each manager should have its own focused element
        #expect(manager1.currentFocusedID == "test-1")
        #expect(manager2.currentFocusedID == "test-2")

        // Clearing one shouldn't affect the other
        manager1.clear()
        #expect(manager1.currentFocusedID == nil)
        #expect(manager2.currentFocusedID == "test-2")
    }
}

// MARK: - Focus Manager Vertical Vim Navigation Tests

@MainActor
@Suite("FocusManager Vertical Vim Navigation Tests")
struct FocusManagerVerticalVimTests {

    @Test("Default style — j/k are not consumed")
    func defaultStyleIgnoresJK() {
        let manager = FocusManager()
        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)
        // verticalNavigationStyles defaults to [.arrowKey]

        let jHandled = manager.dispatchKeyEvent(KeyEvent(key: .character("j")))
        let kHandled = manager.dispatchKeyEvent(KeyEvent(key: .character("k")))

        #expect(jHandled == false)
        #expect(kHandled == false)
        #expect(manager.isFocused(e1))  // Focus unchanged
    }

    @Test("Vertical vim — j moves focus to next element in section")
    func jMovesToNextInSection() {
        let manager = FocusManager()
        manager.verticalNavigationStyles = [.vim]

        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)

        let handled = manager.dispatchKeyEvent(KeyEvent(key: .character("j")))

        #expect(handled == true)
        #expect(manager.isFocused(e2))
    }

    @Test("Vertical vim — k moves focus to previous element in section")
    func kMovesToPreviousInSection() {
        let manager = FocusManager()
        manager.verticalNavigationStyles = [.vim]

        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)
        manager.focus(e2)

        let handled = manager.dispatchKeyEvent(KeyEvent(key: .character("k")))

        #expect(handled == true)
        #expect(manager.isFocused(e1))
    }

    @Test("Vertical vim only — arrow keys are not consumed as section navigation")
    func vimOnlyArrowKeysNotConsumedByFallback() {
        let manager = FocusManager()
        manager.verticalNavigationStyles = [.vim]

        let e1 = MockFocusable(id: "a", shouldConsumeEvents: false)
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)

        // .down should not be handled by the fallback when arrowKey style is absent
        let downHandled = manager.dispatchKeyEvent(KeyEvent(key: .down))

        #expect(downHandled == false)
        #expect(manager.isFocused(e1))  // Focus not changed
    }

    @Test("Both vertical styles — j and down arrow both navigate")
    func bothVerticalStylesWork() {
        let manager = FocusManager()
        manager.verticalNavigationStyles = [.arrowKey, .vim]

        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        let e3 = MockFocusable(id: "c")
        manager.register(e1)
        manager.register(e2)
        manager.register(e3)

        let downHandled = manager.dispatchKeyEvent(KeyEvent(key: .down))
        #expect(downHandled == true)
        #expect(manager.isFocused(e2))

        let jHandled = manager.dispatchKeyEvent(KeyEvent(key: .character("j")))
        #expect(jHandled == true)
        #expect(manager.isFocused(e3))
    }

    @Test("beginRenderPass resets vertical styles to arrowKey default")
    func beginRenderPassResetsVerticalStyles() {
        let manager = FocusManager()
        manager.verticalNavigationStyles = [.vim]

        manager.beginRenderPass()

        // After reset, vim keys should not be consumed
        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)

        let jHandled = manager.dispatchKeyEvent(KeyEvent(key: .character("j")))
        #expect(jHandled == false)

        // Arrow keys should work again
        let downHandled = manager.dispatchKeyEvent(KeyEvent(key: .down))
        #expect(downHandled == true)
    }
}

// MARK: - Focus Manager Horizontal Vim Navigation Tests

@MainActor
@Suite("FocusManager Horizontal Vim Navigation Tests")
struct FocusManagerHorizontalVimTests {

    @Test("Default style — h/l are not consumed")
    func defaultStyleIgnoresHL() {
        let manager = FocusManager()
        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)
        // horizontalNavigationStyles defaults to [.tab]

        let lHandled = manager.dispatchKeyEvent(KeyEvent(key: .character("l")))
        let hHandled = manager.dispatchKeyEvent(KeyEvent(key: .character("h")))

        #expect(lHandled == false)
        #expect(hHandled == false)
        #expect(manager.isFocused(e1))  // Focus unchanged
    }

    @Test("Horizontal vim — l cycles to next focusable")
    func lCyclesToNext() {
        let manager = FocusManager()
        manager.horizontalNavigationStyles = [.vim]

        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)

        let handled = manager.dispatchKeyEvent(KeyEvent(key: .character("l")))

        #expect(handled == true)
        #expect(manager.isFocused(e2))
    }

    @Test("Horizontal vim — h cycles to previous focusable")
    func hCyclesToPrevious() {
        let manager = FocusManager()
        manager.horizontalNavigationStyles = [.vim]

        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)
        manager.focus(e2)

        let handled = manager.dispatchKeyEvent(KeyEvent(key: .character("h")))

        #expect(handled == true)
        #expect(manager.isFocused(e1))
    }

    @Test("Horizontal vim only — Tab is not consumed")
    func vimOnlyTabNotConsumed() {
        let manager = FocusManager()
        manager.horizontalNavigationStyles = [.vim]

        let e1 = MockFocusable(id: "a", shouldConsumeEvents: false)
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)

        let tabHandled = manager.dispatchKeyEvent(KeyEvent(key: .tab))

        #expect(tabHandled == false)
        #expect(manager.isFocused(e1))  // Focus not changed by Tab
    }

    @Test("Tab only — l/h are not consumed")
    func tabOnlyIgnoresHL() {
        let manager = FocusManager()
        // horizontalNavigationStyles defaults to [.tab]

        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)

        let lHandled = manager.dispatchKeyEvent(KeyEvent(key: .character("l")))
        #expect(lHandled == false)
        #expect(manager.isFocused(e1))
    }

    @Test("Tab only — Tab still cycles focus")
    func tabOnlyTabWorks() {
        let manager = FocusManager()
        // horizontalNavigationStyles defaults to [.tab]

        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)

        let handled = manager.dispatchKeyEvent(KeyEvent(key: .tab))

        #expect(handled == true)
        #expect(manager.isFocused(e2))
    }

    @Test("Both horizontal styles — Tab and h/l all cycle focus")
    func bothHorizontalStylesWork() {
        let manager = FocusManager()
        manager.horizontalNavigationStyles = [.tab, .vim]

        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        let e3 = MockFocusable(id: "c")
        manager.register(e1)
        manager.register(e2)
        manager.register(e3)

        let tabHandled = manager.dispatchKeyEvent(KeyEvent(key: .tab))
        #expect(tabHandled == true)
        #expect(manager.isFocused(e2))

        let lHandled = manager.dispatchKeyEvent(KeyEvent(key: .character("l")))
        #expect(lHandled == true)
        #expect(manager.isFocused(e3))

        let hHandled = manager.dispatchKeyEvent(KeyEvent(key: .character("h")))
        #expect(hHandled == true)
        #expect(manager.isFocused(e2))
    }

    @Test("beginRenderPass resets horizontal styles to tab default")
    func beginRenderPassResetsHorizontalStyles() {
        let manager = FocusManager()
        manager.horizontalNavigationStyles = [.vim]

        manager.beginRenderPass()

        // After reset, vim h/l should not be consumed
        let e1 = MockFocusable(id: "a")
        let e2 = MockFocusable(id: "b")
        manager.register(e1)
        manager.register(e2)

        let lHandled = manager.dispatchKeyEvent(KeyEvent(key: .character("l")))
        #expect(lHandled == false)

        // Tab should work again
        let tabHandled = manager.dispatchKeyEvent(KeyEvent(key: .tab))
        #expect(tabHandled == true)
    }
}
