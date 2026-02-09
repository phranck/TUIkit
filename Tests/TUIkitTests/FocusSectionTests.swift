//  TUIKit - Terminal UI Kit for Swift
//  FocusSectionTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

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
