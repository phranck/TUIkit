//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StatusBarItemTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Status Bar Item Tests

@MainActor
@Suite("Status Bar Item Tests")
struct StatusBarItemTests {

    @Test("StatusBarItem with action")
    func itemWithAction() {
        // Use a class to track execution since the closure is @Sendable
        final class ExecutionTracker: @unchecked Sendable {
            var wasExecuted = false
        }
        let tracker = ExecutionTracker()

        let item = StatusBarItem(shortcut: "x", label: "execute") {
            tracker.wasExecuted = true
        }

        item.execute()
        #expect(tracker.wasExecuted == true)
    }

    @Test("StatusBarItem derives key from single character")
    func deriveKeyFromCharacter() {
        let item = StatusBarItem(shortcut: "q", label: "quit")

        #expect(item.triggerKey == .character("q"))
    }

    @Test("StatusBarItem derives key from escape symbol")
    func deriveKeyFromEscape() {
        let item = StatusBarItem(shortcut: Shortcut.escape, label: "close")

        #expect(item.triggerKey == .escape)
    }

    @Test("StatusBarItem derives key from enter symbol")
    func deriveKeyFromEnter() {
        let item = StatusBarItem(shortcut: Shortcut.enter, label: "confirm")

        #expect(item.triggerKey == .enter)
    }

    @Test("StatusBarItem with explicit key")
    func itemWithExplicitKey() {
        let item = StatusBarItem(
            shortcut: "navigate",
            label: "nav",
            key: .up
        )

        #expect(item.triggerKey == .up)
    }

    @Test("StatusBarItem informational has no trigger key")
    func informationalItem() {
        // Multi-character shortcut without explicit key
        let item = StatusBarItem(shortcut: "↑↓", label: "nav")

        // Arrow combinations don't have a single trigger key
        // but matches() handles them specially
        #expect(item.triggerKey == nil)
    }

    @Test("StatusBarItem matches character key")
    func matchesCharacterKey() {
        let item = StatusBarItem(shortcut: "q", label: "quit")

        let event = KeyEvent(key: .character("q"))
        #expect(item.matches(event) == true)

        let wrongEvent = KeyEvent(key: .character("x"))
        #expect(item.matches(wrongEvent) == false)
    }

    @Test("StatusBarItem case sensitive matching")
    func caseSensitiveMatching() {
        let lowerItem = StatusBarItem(shortcut: "n", label: "new")
        let upperItem = StatusBarItem(shortcut: "N", label: "New")

        let lowerEvent = KeyEvent(key: .character("n"))
        let upperEvent = KeyEvent(key: .character("N"))

        #expect(lowerItem.matches(lowerEvent) == true)
        #expect(lowerItem.matches(upperEvent) == false)

        #expect(upperItem.matches(upperEvent) == true)
        #expect(upperItem.matches(lowerEvent) == false)
    }

    @Test("StatusBarItem matches arrow combinations")
    func matchesArrowCombinations() {
        let item = StatusBarItem(shortcut: "↑↓", label: "nav")

        let upEvent = KeyEvent(key: .up)
        let downEvent = KeyEvent(key: .down)
        let leftEvent = KeyEvent(key: .left)

        #expect(item.matches(upEvent) == true)
        #expect(item.matches(downEvent) == true)
        #expect(item.matches(leftEvent) == false)
    }

    @Test("StatusBarItem matches all arrows")
    func matchesAllArrows() {
        let item = StatusBarItem(shortcut: Shortcut.arrowsAll, label: "move")

        #expect(item.matches(KeyEvent(key: .up)) == true)
        #expect(item.matches(KeyEvent(key: .down)) == true)
        #expect(item.matches(KeyEvent(key: .left)) == true)
        #expect(item.matches(KeyEvent(key: .right)) == true)
    }
}

// MARK: - Status Bar Item Builder Tests

@MainActor
@Suite("Status Bar Item Builder Tests")
struct StatusBarItemBuilderTests {

    @Test("Builder buildBlock combines arrays")
    func builderCreatesArray() {
        let items = StatusBarItemBuilder.buildBlock(
            [StatusBarItem(shortcut: "a", label: "a")],
            [StatusBarItem(shortcut: "b", label: "b")]
        )

        #expect(items.count == 2)
    }

    @Test("Builder handles expression")
    func builderHandlesExpression() {
        let item = StatusBarItem(shortcut: "e", label: "expr")
        let result = StatusBarItemBuilder.buildExpression(item)

        #expect(result.count == 1)
    }
}
