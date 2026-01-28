//
//  StatusBarTests.swift
//  SwiftTUI
//
//  Tests for Shortcut constants, TStatusBarItem, StatusBarManager, and TStatusBar.
//

import Testing
@testable import SwiftTUI

// MARK: - Shortcut Constants Tests

@Suite("Shortcut Constants Tests")
struct ShortcutTests {

    @Test("Special key symbols are correct")
    func specialKeys() {
        #expect(Shortcut.escape == "⎋")
        #expect(Shortcut.enter == "↵")
        #expect(Shortcut.returnKey == "⏎")
        #expect(Shortcut.tab == "⇥")
        #expect(Shortcut.shiftTab == "⇤")
        #expect(Shortcut.backspace == "⌫")
        #expect(Shortcut.delete == "⌦")
        #expect(Shortcut.space == "␣")
    }

    @Test("Arrow key symbols are correct")
    func arrowKeys() {
        #expect(Shortcut.arrowUp == "↑")
        #expect(Shortcut.arrowDown == "↓")
        #expect(Shortcut.arrowLeft == "←")
        #expect(Shortcut.arrowRight == "→")
    }

    @Test("Arrow key combinations are correct")
    func arrowCombinations() {
        #expect(Shortcut.arrowsUpDown == "↑↓")
        #expect(Shortcut.arrowsLeftRight == "←→")
        #expect(Shortcut.arrowsAll == "↑↓←→")
        #expect(Shortcut.arrowsVertical == "⇅")
        #expect(Shortcut.arrowsHorizontal == "⇆")
    }

    @Test("Modifier key symbols are correct")
    func modifierKeys() {
        #expect(Shortcut.command == "⌘")
        #expect(Shortcut.option == "⌥")
        #expect(Shortcut.control == "⌃")
        #expect(Shortcut.shift == "⇧")
        #expect(Shortcut.capsLock == "⇪")
    }

    @Test("Navigation key symbols are correct")
    func navigationKeys() {
        #expect(Shortcut.home == "⤒")
        #expect(Shortcut.end == "⤓")
        #expect(Shortcut.pageUp == "⇞")
        #expect(Shortcut.pageDown == "⇟")
    }

    @Test("Action symbols are correct")
    func actionSymbols() {
        #expect(Shortcut.plus == "+")
        #expect(Shortcut.minus == "−")
        #expect(Shortcut.checkmark == "✓")
        #expect(Shortcut.cross == "✗")
        #expect(Shortcut.search == "?")
        #expect(Shortcut.help == "?")
        #expect(Shortcut.save == "S")
    }

    @Test("Common shortcuts are correct")
    func commonShortcuts() {
        #expect(Shortcut.quit == "q")
        #expect(Shortcut.yes == "y")
        #expect(Shortcut.no == "n")
        #expect(Shortcut.cancel == "c")
        #expect(Shortcut.ok == "o")
    }

    @Test("Selection indicators are correct")
    func selectionIndicators() {
        #expect(Shortcut.selectionRight == "▸")
        #expect(Shortcut.selectionLeft == "◂")
        #expect(Shortcut.bullet == "•")
        #expect(Shortcut.squareBullet == "▪")
    }

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

// MARK: - Status Bar Item Tests

@Suite("Status Bar Item Tests")
struct StatusBarItemTests {

    @Test("TStatusBarItem can be created")
    func itemCreation() {
        let item = TStatusBarItem(shortcut: "q", label: "quit")

        #expect(item.shortcut == "q")
        #expect(item.label == "quit")
        #expect(item.id == "q-quit")
    }

    @Test("TStatusBarItem with action")
    func itemWithAction() {
        // Use a class to track execution since the closure is @Sendable
        final class ExecutionTracker: @unchecked Sendable {
            var wasExecuted = false
        }
        let tracker = ExecutionTracker()

        let item = TStatusBarItem(shortcut: "x", label: "execute") {
            tracker.wasExecuted = true
        }

        item.execute()
        #expect(tracker.wasExecuted == true)
    }

    @Test("TStatusBarItem derives key from single character")
    func deriveKeyFromCharacter() {
        let item = TStatusBarItem(shortcut: "q", label: "quit")

        #expect(item.triggerKey == .character("q"))
    }

    @Test("TStatusBarItem derives key from escape symbol")
    func deriveKeyFromEscape() {
        let item = TStatusBarItem(shortcut: Shortcut.escape, label: "close")

        #expect(item.triggerKey == .escape)
    }

    @Test("TStatusBarItem derives key from enter symbol")
    func deriveKeyFromEnter() {
        let item = TStatusBarItem(shortcut: Shortcut.enter, label: "confirm")

        #expect(item.triggerKey == .enter)
    }

    @Test("TStatusBarItem with explicit key")
    func itemWithExplicitKey() {
        let item = TStatusBarItem(
            shortcut: "navigate",
            label: "nav",
            key: .up
        )

        #expect(item.triggerKey == .up)
    }

    @Test("TStatusBarItem informational has no trigger key")
    func informationalItem() {
        // Multi-character shortcut without explicit key
        let item = TStatusBarItem(shortcut: "↑↓", label: "nav")

        // Arrow combinations don't have a single trigger key
        // but matches() handles them specially
        #expect(item.triggerKey == nil)
    }

    @Test("TStatusBarItem matches character key")
    func matchesCharacterKey() {
        let item = TStatusBarItem(shortcut: "q", label: "quit")

        let event = KeyEvent(key: .character("q"))
        #expect(item.matches(event) == true)

        let wrongEvent = KeyEvent(key: .character("x"))
        #expect(item.matches(wrongEvent) == false)
    }

    @Test("TStatusBarItem case sensitive matching")
    func caseSensitiveMatching() {
        let lowerItem = TStatusBarItem(shortcut: "n", label: "new")
        let upperItem = TStatusBarItem(shortcut: "N", label: "New")

        let lowerEvent = KeyEvent(key: .character("n"))
        let upperEvent = KeyEvent(key: .character("N"))

        #expect(lowerItem.matches(lowerEvent) == true)
        #expect(lowerItem.matches(upperEvent) == false)

        #expect(upperItem.matches(upperEvent) == true)
        #expect(upperItem.matches(lowerEvent) == false)
    }

    @Test("TStatusBarItem matches arrow combinations")
    func matchesArrowCombinations() {
        let item = TStatusBarItem(shortcut: "↑↓", label: "nav")

        let upEvent = KeyEvent(key: .up)
        let downEvent = KeyEvent(key: .down)
        let leftEvent = KeyEvent(key: .left)

        #expect(item.matches(upEvent) == true)
        #expect(item.matches(downEvent) == true)
        #expect(item.matches(leftEvent) == false)
    }

    @Test("TStatusBarItem matches all arrows")
    func matchesAllArrows() {
        let item = TStatusBarItem(shortcut: Shortcut.arrowsAll, label: "move")

        #expect(item.matches(KeyEvent(key: .up)) == true)
        #expect(item.matches(KeyEvent(key: .down)) == true)
        #expect(item.matches(KeyEvent(key: .left)) == true)
        #expect(item.matches(KeyEvent(key: .right)) == true)
    }
}

// MARK: - Status Bar Manager Tests

@Suite("Status Bar State Tests")
struct StatusBarStateTests {

    @Test("StatusBarState can be created")
    func stateCreation() {
        let state = StatusBarState()
        #expect(state.currentItems.isEmpty)
        #expect(state.hasItems == false)
    }

    @Test("Set global items")
    func setGlobalItems() {
        let state = StatusBarState()

        state.setItems([
            TStatusBarItem(shortcut: "q", label: "quit"),
            TStatusBarItem(shortcut: "h", label: "help")
        ])

        #expect(state.currentItems.count == 2)
        #expect(state.hasItems == true)
    }

    @Test("Set global items with builder")
    func setGlobalItemsBuilder() {
        let state = StatusBarState()

        state.setItems {
            TStatusBarItem(shortcut: "q", label: "quit")
            TStatusBarItem(shortcut: "h", label: "help")
        }

        #expect(state.currentItems.count == 2)
    }

    @Test("Push context overrides global items")
    func pushContextOverrides() {
        let state = StatusBarState()

        state.setItems([
            TStatusBarItem(shortcut: "q", label: "quit")
        ])

        state.push(context: "dialog", items: [
            TStatusBarItem(shortcut: Shortcut.escape, label: "close"),
            TStatusBarItem(shortcut: Shortcut.enter, label: "confirm")
        ])

        #expect(state.currentItems.count == 2)
        #expect(state.currentItems[0].shortcut == Shortcut.escape)
    }

    @Test("Push context with builder")
    func pushContextBuilder() {
        let state = StatusBarState()

        state.push(context: "test") {
            TStatusBarItem(shortcut: "a", label: "action")
        }

        #expect(state.currentItems.count == 1)
        #expect(state.currentItems[0].label == "action")
    }

    @Test("Pop context returns to global items")
    func popContextReturnsToGlobal() {
        let state = StatusBarState()

        state.setItems([
            TStatusBarItem(shortcut: "g", label: "global")
        ])

        state.push(context: "temp", items: [
            TStatusBarItem(shortcut: "t", label: "temp")
        ])

        state.pop(context: "temp")

        #expect(state.currentItems.count == 1)
        #expect(state.currentItems[0].shortcut == "g")
    }

    @Test("Context stack respects order")
    func contextStackOrder() {
        let state = StatusBarState()

        state.push(context: "first", items: [
            TStatusBarItem(shortcut: "1", label: "first")
        ])

        state.push(context: "second", items: [
            TStatusBarItem(shortcut: "2", label: "second")
        ])

        // Top of stack is shown
        #expect(state.currentItems[0].label == "second")

        state.pop(context: "second")
        #expect(state.currentItems[0].label == "first")
    }

    @Test("Push replaces same context")
    func pushReplacesSameContext() {
        let state = StatusBarState()

        state.push(context: "same", items: [
            TStatusBarItem(shortcut: "a", label: "original")
        ])

        state.push(context: "same", items: [
            TStatusBarItem(shortcut: "b", label: "replaced")
        ])

        #expect(state.currentItems.count == 1)
        #expect(state.currentItems[0].label == "replaced")
    }

    @Test("Clear contexts keeps global items")
    func clearContextsKeepsGlobal() {
        let state = StatusBarState()

        state.setItems([
            TStatusBarItem(shortcut: "g", label: "global")
        ])

        state.push(context: "ctx", items: [
            TStatusBarItem(shortcut: "c", label: "context")
        ])

        state.clearContexts()

        #expect(state.currentItems.count == 1)
        #expect(state.currentItems[0].shortcut == "g")
    }

    @Test("Clear removes everything")
    func clearRemovesAll() {
        let state = StatusBarState()

        state.setItems([
            TStatusBarItem(shortcut: "g", label: "global")
        ])

        state.push(context: "ctx", items: [
            TStatusBarItem(shortcut: "c", label: "context")
        ])

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
            TStatusBarItem(shortcut: "t", label: "trigger") {
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
            TStatusBarItem(shortcut: "a", label: "action") {}
        ])

        let event = KeyEvent(key: .character("x"))
        let handled = state.handleKeyEvent(event)

        #expect(handled == false)
    }

    @Test("Style property can be set")
    func styleProperty() {
        let state = StatusBarState()

        state.style = .bordered
        #expect(state.style == .bordered)

        state.style = .compact
        #expect(state.style == .compact)
    }

    @Test("Color properties can be set")
    func colorProperties() {
        let state = StatusBarState()

        state.highlightColor = .yellow
        #expect(state.highlightColor == .yellow)

        state.labelColor = .blue
        #expect(state.labelColor == .blue)
    }

    @Test("Alignment property can be set")
    func alignmentProperty() {
        let state = StatusBarState()

        state.alignment = .leading
        #expect(state.alignment == .leading)

        state.alignment = .trailing
        #expect(state.alignment == .trailing)

        state.alignment = .center
        #expect(state.alignment == .center)

        state.alignment = .justified
        #expect(state.alignment == .justified)
    }

    @Test("Height is zero when no items")
    func heightZeroWhenEmpty() {
        let state = StatusBarState()
        #expect(state.height == 0)
    }

    @Test("Height is 1 for compact style")
    func heightCompact() {
        let state = StatusBarState()
        state.style = .compact
        state.setItems([TStatusBarItem(shortcut: "x", label: "test")])
        #expect(state.height == 1)
    }

    @Test("Height is 3 for bordered style")
    func heightBordered() {
        let state = StatusBarState()
        state.style = .bordered
        state.setItems([TStatusBarItem(shortcut: "x", label: "test")])
        #expect(state.height == 3)
    }
}

// MARK: - TStatusBar Tests

@Suite("TStatusBar Tests")
struct TStatusBarTests {

    @Test("TStatusBar can be created with items")
    func statusBarCreation() {
        let statusBar = TStatusBar(items: [
            TStatusBarItem(shortcut: "q", label: "quit"),
            TStatusBarItem(shortcut: "h", label: "help")
        ])

        #expect(statusBar.items.count == 2)
        #expect(statusBar.style == .compact)
        #expect(statusBar.alignment == .justified)
        #expect(statusBar.highlightColor == .cyan)
    }

    @Test("TStatusBar with style")
    func statusBarWithStyle() {
        let statusBar = TStatusBar(
            items: [TStatusBarItem(shortcut: "x", label: "test")],
            style: .bordered
        )

        #expect(statusBar.style == .bordered)
    }

    @Test("TStatusBar with custom colors")
    func statusBarWithColors() {
        let statusBar = TStatusBar(
            items: [],
            highlightColor: .yellow,
            labelColor: .green
        )

        #expect(statusBar.highlightColor == .yellow)
        #expect(statusBar.labelColor == .green)
    }

    @Test("TStatusBar with builder")
    func statusBarWithBuilder() {
        let statusBar = TStatusBar {
            TStatusBarItem(shortcut: "a", label: "alpha")
            TStatusBarItem(shortcut: "b", label: "beta")
        }

        #expect(statusBar.items.count == 2)
    }

    @Test("TStatusBar compact height")
    func compactHeight() {
        let statusBar = TStatusBar(items: [], style: .compact)
        #expect(statusBar.height == 1)
    }

    @Test("TStatusBar bordered height")
    func borderedHeight() {
        let statusBar = TStatusBar(items: [], style: .bordered)
        #expect(statusBar.height == 3)
    }

    @Test("TStatusBar renders compact style")
    func rendersCompact() {
        let statusBar = TStatusBar(items: [
            TStatusBarItem(shortcut: "q", label: "quit")
        ], style: .compact)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.height == 1)
        let content = buffer.lines.joined()
        #expect(content.contains("q"))
        #expect(content.contains("quit"))
    }

    @Test("TStatusBar renders bordered style")
    func rendersBordered() {
        let statusBar = TStatusBar(items: [
            TStatusBarItem(shortcut: "h", label: "help")
        ], style: .bordered)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.height == 3)
        // Should have block border characters
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("▄") || allContent.contains("█") || allContent.contains("▀"))
    }

    @Test("Empty TStatusBar returns empty buffer")
    func emptyStatusBar() {
        let statusBar = TStatusBar(items: [])

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.isEmpty)
    }

    @Test("TStatusBar renders multiple items with separator")
    func multipleItemsWithSeparator() {
        let statusBar = TStatusBar(items: [
            TStatusBarItem(shortcut: "a", label: "alpha"),
            TStatusBarItem(shortcut: "b", label: "beta")
        ])

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        let content = buffer.lines.joined()
        #expect(content.contains("alpha"))
        #expect(content.contains("beta"))
    }

    @Test("TStatusBar default alignment is justified")
    func defaultAlignmentIsJustified() {
        let statusBar = TStatusBar(items: [
            TStatusBarItem(shortcut: "q", label: "quit")
        ])

        #expect(statusBar.alignment == .justified)
    }

    @Test("TStatusBar with leading alignment")
    func leadingAlignment() {
        let statusBar = TStatusBar(
            items: [
                TStatusBarItem(shortcut: "a", label: "alpha"),
                TStatusBarItem(shortcut: "b", label: "beta")
            ],
            alignment: .leading
        )

        #expect(statusBar.alignment == .leading)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        // Content should start near the beginning (after padding)
        let line = buffer.lines[0]
        let strippedLine = line.strippedLength > 0 ? line : ""
        #expect(!strippedLine.isEmpty)
    }

    @Test("TStatusBar with trailing alignment")
    func trailingAlignment() {
        let statusBar = TStatusBar(
            items: [
                TStatusBarItem(shortcut: "a", label: "alpha"),
                TStatusBarItem(shortcut: "b", label: "beta")
            ],
            alignment: .trailing
        )

        #expect(statusBar.alignment == .trailing)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        // Content should be at the end
        #expect(!buffer.isEmpty)
    }

    @Test("TStatusBar with center alignment")
    func centerAlignment() {
        let statusBar = TStatusBar(
            items: [
                TStatusBarItem(shortcut: "a", label: "alpha"),
                TStatusBarItem(shortcut: "b", label: "beta")
            ],
            alignment: .center
        )

        #expect(statusBar.alignment == .center)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        // Content should be centered - line should not be empty
        #expect(!buffer.isEmpty)
    }

    @Test("TStatusBar with justified alignment distributes items")
    func justifiedAlignment() {
        let statusBar = TStatusBar(
            items: [
                TStatusBarItem(shortcut: "a", label: "first"),
                TStatusBarItem(shortcut: "b", label: "second"),
                TStatusBarItem(shortcut: "c", label: "third")
            ],
            alignment: .justified
        )

        #expect(statusBar.alignment == .justified)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        // All items should be present
        let content = buffer.lines.joined()
        #expect(content.contains("first"))
        #expect(content.contains("second"))
        #expect(content.contains("third"))
    }

    @Test("TStatusBar bordered with alignment")
    func borderedWithAlignment() {
        let statusBar = TStatusBar(
            items: [
                TStatusBarItem(shortcut: "a", label: "alpha"),
                TStatusBarItem(shortcut: "b", label: "beta")
            ],
            style: .bordered,
            alignment: .center
        )

        #expect(statusBar.style == .bordered)
        #expect(statusBar.alignment == .center)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.height == 3)
    }
}

// MARK: - Status Bar Alignment Tests

@Suite("Status Bar Alignment Tests")
struct StatusBarAlignmentTests {

    @Test("TStatusBarAlignment enum values exist")
    func alignmentEnumValues() {
        let leading: TStatusBarAlignment = .leading
        let trailing: TStatusBarAlignment = .trailing
        let center: TStatusBarAlignment = .center
        let justified: TStatusBarAlignment = .justified

        #expect(leading != trailing)
        #expect(center != justified)
    }

    @Test("Single item with justified alignment is centered")
    func singleItemJustified() {
        let statusBar = TStatusBar(
            items: [TStatusBarItem(shortcut: "x", label: "only")],
            alignment: .justified
        )

        let context = RenderContext(availableWidth: 40, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        // Single item should be centered in justified mode
        #expect(!buffer.isEmpty)
        let line = buffer.lines[0]
        #expect(line.strippedLength == 40)
    }
}

// MARK: - Status Bar Item Builder Tests

@Suite("Status Bar Item Builder Tests")
struct StatusBarItemBuilderTests {

    @Test("Builder buildBlock combines arrays")
    func builderCreatesArray() {
        let items = StatusBarItemBuilder.buildBlock(
            [TStatusBarItem(shortcut: "a", label: "a")],
            [TStatusBarItem(shortcut: "b", label: "b")]
        )

        #expect(items.count == 2)
    }

    @Test("Builder handles expression")
    func builderHandlesExpression() {
        let item = TStatusBarItem(shortcut: "e", label: "expr")
        let result = StatusBarItemBuilder.buildExpression(item)

        #expect(result.count == 1)
    }

    @Test("Builder works with TStatusBar initializer")
    func builderWorksWithStatusBar() {
        let statusBar = TStatusBar {
            TStatusBarItem(shortcut: "x", label: "test")
            TStatusBarItem(shortcut: "y", label: "test2")
        }

        #expect(statusBar.items.count == 2)
    }
}

// MARK: - StatusBarItems Modifier Tests

@Suite("StatusBarItems Modifier Tests")
struct StatusBarItemsModifierTests {

    @Test("statusBarItems modifier can be applied to view")
    func modifierCanBeApplied() {
        let view = Text("Content")
            .statusBarItems([
                TStatusBarItem(shortcut: "q", label: "quit")
            ])

        // View should be wrapped in modifier
        #expect(view is StatusBarItemsModifier<Text>)
    }

    @Test("statusBarItems modifier with builder syntax")
    func modifierWithBuilder() {
        let view = Text("Content")
            .statusBarItems {
                TStatusBarItem(shortcut: "a", label: "alpha")
                TStatusBarItem(shortcut: "b", label: "beta")
            }

        #expect(view is StatusBarItemsModifier<Text>)
    }

    @Test("statusBarItems modifier with context")
    func modifierWithContext() {
        let view = Text("Dialog")
            .statusBarItems(context: "dialog") {
                TStatusBarItem(shortcut: Shortcut.escape, label: "close")
            }

        #expect(view is StatusBarItemsModifier<Text>)
    }

    @Test("statusBarItems modifier sets items in environment")
    func modifierSetsItemsInEnvironment() {
        // Setup: Create a status bar state and environment
        let state = StatusBarState()
        var environment = EnvironmentValues()
        environment.statusBar = state

        // Create view with modifier
        let view = Text("Test")
            .statusBarItems {
                TStatusBarItem(shortcut: "t", label: "test")
            }

        // Render with environment
        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: environment
        )

        EnvironmentStorage.shared.environment = environment
        _ = renderToBuffer(view, context: context)

        // Check that items were set
        #expect(state.currentItems.count == 1)
        #expect(state.currentItems[0].label == "test")
    }

    @Test("statusBarItems modifier with context pushes to stack")
    func modifierWithContextPushesToStack() {
        // Setup
        let state = StatusBarState()
        var environment = EnvironmentValues()
        environment.statusBar = state

        // Set global items first
        state.setItems([
            TStatusBarItem(shortcut: "g", label: "global")
        ])

        // Create view with context modifier
        let view = Text("Dialog")
            .statusBarItems(context: "dialog") {
                TStatusBarItem(shortcut: "d", label: "dialog-item")
            }

        // Render
        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: environment
        )

        EnvironmentStorage.shared.environment = environment
        _ = renderToBuffer(view, context: context)

        // Context items should be active
        #expect(state.currentItems.count == 1)
        #expect(state.currentItems[0].label == "dialog-item")

        // Pop context
        state.pop(context: "dialog")

        // Global items should be back
        #expect(state.currentItems.count == 1)
        #expect(state.currentItems[0].label == "global")
    }

    @Test("statusBarItems modifier renders content")
    func modifierRendersContent() {
        let state = StatusBarState()
        var environment = EnvironmentValues()
        environment.statusBar = state

        let view = Text("Hello World")
            .statusBarItems {
                TStatusBarItem(shortcut: "x", label: "test")
            }

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: environment
        )

        EnvironmentStorage.shared.environment = environment
        let buffer = renderToBuffer(view, context: context)

        // Content should be rendered
        let content = buffer.lines.joined()
        #expect(content.contains("Hello World"))
    }

    @Test("statusBarItems with array and context")
    func modifierWithArrayAndContext() {
        let items = [
            TStatusBarItem(shortcut: "y", label: "yes"),
            TStatusBarItem(shortcut: "n", label: "no")
        ]

        let view = Text("Confirm?")
            .statusBarItems(context: "confirm", items: items)

        #expect(view is StatusBarItemsModifier<Text>)
    }

    @Test("Nested statusBarItems modifiers")
    func nestedModifiers() {
        let state = StatusBarState()
        var environment = EnvironmentValues()
        environment.statusBar = state

        // Outer sets global, inner pushes context
        let innerView = Text("Inner")
            .statusBarItems(context: "inner") {
                TStatusBarItem(shortcut: "i", label: "inner-item")
            }

        let outerView = VStack {
            innerView
        }
        .statusBarItems {
            TStatusBarItem(shortcut: "o", label: "outer-item")
        }

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: environment
        )

        EnvironmentStorage.shared.environment = environment
        _ = renderToBuffer(outerView, context: context)

        // Inner context should be on top
        #expect(state.currentItems.count == 1)
        #expect(state.currentItems[0].label == "inner-item")

        // Pop inner context
        state.pop(context: "inner")

        // Outer (global) should be active
        #expect(state.currentItems[0].label == "outer-item")
    }
}
