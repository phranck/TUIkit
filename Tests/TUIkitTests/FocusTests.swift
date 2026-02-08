//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FocusTests.swift
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

    @Test("Avoid duplicate registration")
    func avoidDuplicates() {
        let manager = FocusManager()

        let element = MockFocusable(id: "unique-element")
        manager.register(element)
        manager.register(element)

        // Should still work without issues
        #expect(manager.isFocused(element))
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

// MARK: - Focus State Tests

@MainActor
@Suite("Focus State Tests", .serialized)
struct FocusStateTests {

    @Test("FocusState generates UUID if no ID provided")
    func focusStateGeneratesUUID() {
        let manager = FocusManager()
        let state = FocusState(focusManager: manager)
        #expect(!state.id.isEmpty)
        // UUID format check
        #expect(state.id.contains("-"))
    }

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

// MARK: - Focus Section Tests

@MainActor
@Suite("Focus Section Tests")
struct FocusSectionTests {

    @Test("Register section and auto-activate first")
    func registerSectionAutoActivate() {
        let manager = FocusManager()

        manager.registerSection(id: "sidebar")
        manager.registerSection(id: "content")

        #expect(manager.isActiveSection("sidebar"))
        #expect(!manager.isActiveSection("content"))
        #expect(manager.sectionIDs == ["sidebar", "content"])
    }

    @Test("Duplicate section registration is idempotent")
    func duplicateSectionRegistration() {
        let manager = FocusManager()

        manager.registerSection(id: "panel")
        manager.registerSection(id: "panel")

        #expect(manager.sectionIDs == ["panel"])
    }

    @Test("Tab cycles between sections")
    func tabCyclesSections() {
        let manager = FocusManager()

        manager.registerSection(id: "left")
        manager.registerSection(id: "right")

        let elemLeft = MockFocusable(id: "btn-left")
        let elemRight = MockFocusable(id: "btn-right")

        manager.register(elemLeft, inSection: "left")
        manager.register(elemRight, inSection: "right")

        // left is active, elemLeft is focused
        #expect(manager.isActiveSection("left"))
        #expect(manager.isFocused(elemLeft))

        // Tab → switch to right section
        let tabEvent = KeyEvent(key: .tab, ctrl: false, alt: false, shift: false)
        manager.dispatchKeyEvent(tabEvent)

        #expect(manager.isActiveSection("right"))
        #expect(manager.isFocused(elemRight))
    }

    @Test("Shift+Tab cycles sections backward")
    func shiftTabCyclesBackward() {
        let manager = FocusManager()

        manager.registerSection(id: "a")
        manager.registerSection(id: "b")
        manager.registerSection(id: "c")

        let elemA = MockFocusable(id: "elem-a")
        let elemB = MockFocusable(id: "elem-b")
        let elemC = MockFocusable(id: "elem-c")

        manager.register(elemA, inSection: "a")
        manager.register(elemB, inSection: "b")
        manager.register(elemC, inSection: "c")

        // Start at section "a"
        #expect(manager.isActiveSection("a"))

        // Shift+Tab → wrap to "c"
        let shiftTab = KeyEvent(key: .tab, ctrl: false, alt: false, shift: true)
        manager.dispatchKeyEvent(shiftTab)

        #expect(manager.isActiveSection("c"))
        #expect(manager.isFocused(elemC))
    }

    @Test("Up/Down navigates within active section")
    func upDownWithinSection() {
        let manager = FocusManager()

        manager.registerSection(id: "list")

        let item1 = MockFocusable(id: "item-1")
        let item2 = MockFocusable(id: "item-2")
        let item3 = MockFocusable(id: "item-3")

        manager.register(item1, inSection: "list")
        manager.register(item2, inSection: "list")
        manager.register(item3, inSection: "list")

        // item1 is auto-focused
        #expect(manager.isFocused(item1))

        // Down → item2
        let downEvent = KeyEvent(key: .down, ctrl: false, alt: false, shift: false)
        manager.dispatchKeyEvent(downEvent)
        #expect(manager.isFocused(item2))

        // Down → item3
        manager.dispatchKeyEvent(downEvent)
        #expect(manager.isFocused(item3))

        // Up → item2
        let upEvent = KeyEvent(key: .up, ctrl: false, alt: false, shift: false)
        manager.dispatchKeyEvent(upEvent)
        #expect(manager.isFocused(item2))
    }

    @Test("Activate section by ID focuses first element")
    func activateSectionFocusesFirst() {
        let manager = FocusManager()

        manager.registerSection(id: "sec-a")
        manager.registerSection(id: "sec-b")

        let elemA = MockFocusable(id: "a-btn")
        let elemB = MockFocusable(id: "b-btn")

        manager.register(elemA, inSection: "sec-a")
        manager.register(elemB, inSection: "sec-b")

        // Explicitly activate sec-b
        manager.activateSection(id: "sec-b")

        #expect(manager.isActiveSection("sec-b"))
        #expect(manager.isFocused(elemB))
        #expect(elemA.focusLostCount >= 1, "Previous element should lose focus")
    }

    @Test("beginRenderPass preserves active section ID")
    func beginRenderPassPreservesSection() {
        let manager = FocusManager()

        manager.registerSection(id: "panel")
        let elem = MockFocusable(id: "btn")
        manager.register(elem, inSection: "panel")

        // Activate and verify
        #expect(manager.isActiveSection("panel"))
        #expect(manager.isFocused(elem))

        // beginRenderPass clears sections but preserves IDs
        manager.beginRenderPass()
        #expect(manager.sectionIDs.isEmpty, "Sections cleared during beginRenderPass")

        // Re-register section and element (simulating re-render)
        manager.registerSection(id: "panel")
        manager.register(elem, inSection: "panel")

        // endRenderPass validates — should restore focus
        manager.endRenderPass()

        #expect(manager.isActiveSection("panel"))
        #expect(manager.isFocused(elem))
    }

    @Test("endRenderPass falls back when section removed")
    func endRenderPassFallback() {
        let manager = FocusManager()

        manager.registerSection(id: "modal")
        manager.registerSection(id: "page")
        let modalBtn = MockFocusable(id: "modal-btn")
        let pageBtn = MockFocusable(id: "page-btn")
        manager.register(modalBtn, inSection: "modal")
        manager.register(pageBtn, inSection: "page")

        // Activate modal section
        manager.activateSection(id: "modal")
        #expect(manager.isActiveSection("modal"))

        // Simulate render pass where modal is gone
        manager.beginRenderPass()
        // Only re-register page, not modal
        manager.registerSection(id: "page")
        manager.register(pageBtn, inSection: "page")
        manager.endRenderPass()

        // Should fall back to "page"
        #expect(manager.isActiveSection("page"))
        #expect(manager.isFocused(pageBtn))
    }

    @Test("Single section: Tab cycles elements within it")
    func singleSectionTabCyclesElements() {
        let manager = FocusManager()

        manager.registerSection(id: "only")
        let btn1 = MockFocusable(id: "btn-1")
        let btn2 = MockFocusable(id: "btn-2")
        manager.register(btn1, inSection: "only")
        manager.register(btn2, inSection: "only")

        #expect(manager.isFocused(btn1))

        // With single section, Tab cycles elements (not sections)
        let tabEvent = KeyEvent(key: .tab, ctrl: false, alt: false, shift: false)
        manager.dispatchKeyEvent(tabEvent)

        #expect(manager.isFocused(btn2))
    }
}
