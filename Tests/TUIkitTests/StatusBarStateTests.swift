//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StatusBarStateTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Status Bar State Tests

@MainActor
@Suite("Status Bar State Tests")
struct StatusBarStateTests {

    @Test("StatusBarState can be created with system items")
    func stateCreation() {
        let state = StatusBarState()
        // By default, system items (quit) are present
        #expect(state.hasItems == true)
        #expect(state.currentItems.count >= 1)
        #expect(state.currentItems.contains { $0.shortcut == "q" })
    }

    @Test("StatusBarState without system items is empty")
    func stateWithoutSystemItems() {
        let state = StatusBarState()
        state.showSystemItems = false
        #expect(state.currentItems.isEmpty)
        #expect(state.hasItems == false)
    }

    @Test("Set global items merges with system items")
    func setGlobalItems() {
        let state = StatusBarState()

        state.setItems([
            StatusBarItem(shortcut: "s", label: "save"),
            StatusBarItem(shortcut: "x", label: "extra"),
        ])

        // User items (s, x) + system item (q) = 3 total (appearance/theme off by default)
        #expect(state.currentItems.count == 3)
        #expect(state.hasItems == true)
        #expect(state.currentItems.contains { $0.shortcut == "q" })  // system quit
        #expect(state.currentItems.contains { $0.shortcut == "s" })  // user save
        #expect(state.currentItems.contains { $0.shortcut == "x" })  // user extra
    }

    @Test("Set global items with builder merges with system items")
    func setGlobalItemsBuilder() {
        let state = StatusBarState()

        state.setItems {
            StatusBarItem(shortcut: "s", label: "save")
            StatusBarItem(shortcut: "x", label: "extra")
        }

        // User items (s, x) + system item (q) = 3 total (appearance/theme off by default)
        #expect(state.currentItems.count == 3)
    }

    @Test("Push context overrides global items but keeps system items")
    func pushContextOverrides() {
        let state = StatusBarState()

        state.setItems([
            StatusBarItem(shortcut: "s", label: "save")
        ])

        state.push(
            context: "dialog",
            items: [
                StatusBarItem(shortcut: Shortcut.escape, label: "close"),
                StatusBarItem(shortcut: Shortcut.enter, label: "confirm"),
            ]
        )

        // Context items (escape, enter) + system item (q) = 3 total (appearance/theme off by default)
        #expect(state.currentItems.count == 3)
        #expect(state.currentItems.contains { $0.shortcut == "q" })  // system quit
        #expect(state.currentItems.contains { $0.shortcut == Shortcut.escape })
        #expect(state.currentItems.contains { $0.shortcut == Shortcut.enter })
    }

    @Test("Push context with builder merges with system items")
    func pushContextBuilder() {
        let state = StatusBarState()

        state.push(context: "test") {
            StatusBarItem(shortcut: "x", label: "action")  // Use 'x' to not conflict with 'a' (appearance)
        }

        // Context item (x) + system item (q) = 2 total (appearance/theme off by default)
        #expect(state.currentItems.count == 2)
        #expect(state.currentItems.contains { $0.label == "action" })
        #expect(state.currentItems.contains { $0.shortcut == "q" })
    }

    @Test("Pop context returns to global items with system items")
    func popContextReturnsToGlobal() {
        let state = StatusBarState()

        state.setItems([
            StatusBarItem(shortcut: "g", label: "global")
        ])

        state.push(
            context: "temp",
            items: [
                StatusBarItem(shortcut: "x", label: "temp")
            ]
        )

        state.pop(context: "temp")

        // Global item (g) + system item (q) = 2 total (appearance/theme off by default)
        #expect(state.currentItems.count == 2)
        #expect(state.currentItems.contains { $0.shortcut == "g" })
        #expect(state.currentItems.contains { $0.shortcut == "q" })
    }

    @Test("Context stack respects order")
    func contextStackOrder() {
        let state = StatusBarState()
        state.showSystemItems = false  // Disable system items for cleaner test

        state.push(
            context: "first",
            items: [
                StatusBarItem(shortcut: "1", label: "first")
            ]
        )

        state.push(
            context: "second",
            items: [
                StatusBarItem(shortcut: "2", label: "second")
            ]
        )

        // Top of stack is shown (only user items)
        #expect(state.currentUserItems.count == 1)
        #expect(state.currentUserItems[0].label == "second")

        state.pop(context: "second")
        #expect(state.currentUserItems[0].label == "first")
    }

    @Test("Push replaces same context")
    func pushReplacesSameContext() {
        let state = StatusBarState()
        state.showSystemItems = false  // Disable system items for cleaner test

        state.push(
            context: "same",
            items: [
                StatusBarItem(shortcut: "a", label: "original")
            ]
        )

        state.push(
            context: "same",
            items: [
                StatusBarItem(shortcut: "b", label: "replaced")
            ]
        )

        #expect(state.currentUserItems.count == 1)
        #expect(state.currentUserItems[0].label == "replaced")
    }

    @Test("Clear contexts keeps global user items")
    func clearContextsKeepsGlobal() {
        let state = StatusBarState()
        state.showSystemItems = false  // Disable system items for cleaner test

        state.setItems([
            StatusBarItem(shortcut: "g", label: "global")
        ])

        state.push(
            context: "ctx",
            items: [
                StatusBarItem(shortcut: "c", label: "context")
            ]
        )

        state.clearContexts()

        #expect(state.currentUserItems.count == 1)
        #expect(state.currentUserItems[0].shortcut == "g")
    }

    @Test("Clear removes everything")
    func clearRemovesAll() {
        let state = StatusBarState()

        state.setItems([
            StatusBarItem(shortcut: "g", label: "global")
        ])

        state.push(
            context: "ctx",
            items: [
                StatusBarItem(shortcut: "c", label: "context")
            ]
        )

        state.clear()

        #expect(state.currentItems.isEmpty)
        #expect(state.hasItems == false)
    }

    @Test("Handle key event triggers action")
    func handleKeyEventTriggersAction() {
        let state = StatusBarState()

        // Use a class to track execution since the closure is @Sendable
        final class TriggerTracker: @unchecked Sendable {
            var wasTriggered = false
        }
        let tracker = TriggerTracker()

        state.setItems([
            StatusBarItem(shortcut: "t", label: "trigger") {
                tracker.wasTriggered = true
            }
        ])

        let event = KeyEvent(key: .character("t"))
        let handled = state.handleKeyEvent(event)

        #expect(handled == true)
        #expect(tracker.wasTriggered == true)
    }

    @Test("Handle key event returns false for unmatched")
    func handleKeyEventUnmatched() {
        let state = StatusBarState()

        state.setItems([
            StatusBarItem(shortcut: "a", label: "action") {}
        ])

        let event = KeyEvent(key: .character("x"))
        let handled = state.handleKeyEvent(event)

        #expect(handled == false)
    }

    @Test("Height is zero when no items and system items disabled")
    func heightZeroWhenEmpty() {
        let state = StatusBarState()
        state.showSystemItems = false
        #expect(state.height == 0)
    }

    @Test("Height is 3 when only system items")
    func heightWithSystemItems() {
        let state = StatusBarState()
        // System items are enabled by default, bordered style default
        #expect(state.height == 3)  // bordered style default
    }

    @Test("Height is 1 for compact style")
    func heightCompact() {
        let state = StatusBarState()
        state.style = .compact
        state.setItems([StatusBarItem(shortcut: "x", label: "test")])
        #expect(state.height == 1)
    }

    @Test("Height is 3 for bordered style")
    func heightBordered() {
        let state = StatusBarState()
        state.style = .bordered
        state.setItems([StatusBarItem(shortcut: "x", label: "test")])
        #expect(state.height == 3)
    }
}

// MARK: - System Status Bar Items Tests

@MainActor
@Suite("System Status Bar Items Tests")
struct SystemStatusBarItemsTests {

    @Test("System items are present by default")
    func systemItemsPresentByDefault() {
        let state = StatusBarState()
        #expect(state.showSystemItems == true)
        #expect(state.currentSystemItems.count >= 1)
        #expect(state.currentSystemItems.contains { $0.shortcut == "q" })
    }

    @Test("System items can be disabled")
    func systemItemsCanBeDisabled() {
        let state = StatusBarState()
        state.showSystemItems = false
        #expect(state.currentSystemItems.isEmpty)
    }

    @Test("System items appear on the right (high order values)")
    func systemItemsAppearOnRight() {
        let state = StatusBarState()
        state.setItems([
            StatusBarItem(shortcut: "s", label: "save")
        ])

        // User items should come before system items (lower order)
        let items = state.currentItems
        let saveIndex = items.firstIndex { $0.shortcut == "s" }
        let quitIndex = items.firstIndex { $0.shortcut == "q" }

        #expect(saveIndex != nil)
        #expect(quitIndex != nil)
        #expect(saveIndex! < quitIndex!)  // save appears before quit
    }

    @Test("User items can override system items with same shortcut")
    func userItemsOverrideSystemItems() {
        let state = StatusBarState()

        // Set user item with same shortcut as system quit
        state.setItems([
            StatusBarItem(shortcut: "q", label: "custom-quit") {
                // Custom action
            }
        ])

        // Should only have one "q" item, and it should be the user's
        let qItems = state.currentItems.filter { $0.shortcut == "q" }
        #expect(qItems.count == 1)
        #expect(qItems[0].label == "custom-quit")
    }

    @Test("Items are sorted by order")
    func itemsSortedByOrder() {
        let state = StatusBarState()

        // Add items in random order
        state.setItems([
            StatusBarItem(shortcut: "l", label: "late", order: .late),
            StatusBarItem(shortcut: "e", label: "early", order: .early),
            StatusBarItem(shortcut: "d", label: "default", order: .default),
        ])

        let items = state.currentItems

        // Should be sorted: early, default, late, quit (system)
        let labels = items.map { $0.label }
        let earlyIndex = labels.firstIndex(of: "early")!
        let defaultIndex = labels.firstIndex(of: "default")!
        let lateIndex = labels.firstIndex(of: "late")!
        let quitIndex = labels.firstIndex(of: "quit")!

        #expect(earlyIndex < defaultIndex)
        #expect(defaultIndex < lateIndex)
        #expect(lateIndex < quitIndex)
    }
}

// MARK: - StatusBar Section Cascading Tests

@MainActor
@Suite("StatusBar Section Cascading Tests")
struct StatusBarSectionCascadingTests {

    @Test("Section items with merge include global items")
    func mergeIncludesGlobal() {
        let state = StatusBarState()
        state.showSystemItems = false

        // Set global items
        state.setItemsSilently([
            StatusBarItem(shortcut: Shortcut.escape, label: "back")
        ])

        // Register section items with .merge
        state.registerSectionItems(
            sectionID: "panel",
            items: [StatusBarItem(shortcut: Shortcut.enter, label: "select")],
            composition: .merge
        )

        // Wire up a focus manager with the section active
        let focusManager = FocusManager()
        focusManager.registerSection(id: "panel")
        state.focusManager = focusManager

        let items = state.currentUserItems
        let labels = items.map { $0.label }

        // Both section item and global item should be present
        #expect(labels.contains("select"), "Section item should be present")
        #expect(labels.contains("back"), "Global item should be merged in")
    }

    @Test("Section items with replace exclude global items")
    func replaceExcludesGlobal() {
        let state = StatusBarState()
        state.showSystemItems = false

        // Set global items
        state.setItemsSilently([
            StatusBarItem(shortcut: Shortcut.escape, label: "back")
        ])

        // Register section items with .replace
        state.registerSectionItems(
            sectionID: "modal",
            items: [StatusBarItem(shortcut: Shortcut.escape, label: "close")],
            composition: .replace
        )

        // Wire up focus manager
        let focusManager = FocusManager()
        focusManager.registerSection(id: "modal")
        state.focusManager = focusManager

        let items = state.currentUserItems
        let labels = items.map { $0.label }

        // Only section item, not global
        #expect(labels.contains("close"), "Section item should be present")
        #expect(!labels.contains("back"), "Global item should be replaced")
    }

    @Test("Merge: section item wins on shortcut conflict")
    func mergeChildWinsOnConflict() {
        let state = StatusBarState()
        state.showSystemItems = false

        // Global ESC → "back"
        state.setItemsSilently([
            StatusBarItem(shortcut: Shortcut.escape, label: "back")
        ])

        // Section ESC → "close" (same shortcut, different label)
        state.registerSectionItems(
            sectionID: "dialog",
            items: [StatusBarItem(shortcut: Shortcut.escape, label: "close")],
            composition: .merge
        )

        let focusManager = FocusManager()
        focusManager.registerSection(id: "dialog")
        state.focusManager = focusManager

        let items = state.currentUserItems
        let escItems = items.filter { $0.shortcut == Shortcut.escape }

        // Only one ESC item, and it's the section's
        #expect(escItems.count == 1)
        #expect(escItems[0].label == "close")
    }

    @Test("clearSectionItems resets section items")
    func clearSectionItemsResets() {
        let state = StatusBarState()
        state.showSystemItems = false

        state.registerSectionItems(
            sectionID: "panel",
            items: [StatusBarItem(shortcut: "x", label: "action")],
            composition: .merge
        )

        state.clearSectionItems()

        // Set global items so we have something to compare
        state.setItemsSilently([
            StatusBarItem(shortcut: "g", label: "global")
        ])

        let items = state.currentUserItems
        let labels = items.map { $0.label }

        // Only global items, no section items
        #expect(!labels.contains("action"))
        #expect(labels.contains("global"))
    }

    @Test("Section without items falls through to global")
    func sectionWithoutItemsFallsThrough() {
        let state = StatusBarState()
        state.showSystemItems = false

        // Global items set
        state.setItemsSilently([
            StatusBarItem(shortcut: "g", label: "global")
        ])

        // Register section for a different panel (not the active one)
        state.registerSectionItems(
            sectionID: "other",
            items: [StatusBarItem(shortcut: "o", label: "other")],
            composition: .merge
        )

        // Active section is "sidebar" which has no items registered
        let focusManager = FocusManager()
        focusManager.registerSection(id: "sidebar")
        focusManager.registerSection(id: "other")
        state.focusManager = focusManager

        let items = state.currentUserItems
        let labels = items.map { $0.label }

        // Active section "sidebar" has no items → falls through to global
        #expect(labels.contains("global"))
        #expect(!labels.contains("other"))
    }
}
