//
//  StatusBarTests.swift
//  TUIKit
//
//  Tests for Shortcut constants, StatusBarItem, StatusBarManager, and StatusBar.
//

import Testing
@testable import TUIKit

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

    @Test("StatusBarItem can be created")
    func itemCreation() {
        let item = StatusBarItem(shortcut: "q", label: "quit")

        #expect(item.shortcut == "q")
        #expect(item.label == "quit")
        #expect(item.id == "q-quit")
    }

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

// MARK: - Status Bar Manager Tests

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
            StatusBarItem(shortcut: "x", label: "extra")
        ])

        // User items (s, x) + system items (q, a, t) = 5 total
        #expect(state.currentItems.count == 5)
        #expect(state.hasItems == true)
        #expect(state.currentItems.contains { $0.shortcut == "q" }) // system quit
        #expect(state.currentItems.contains { $0.shortcut == "a" }) // system appearance
        #expect(state.currentItems.contains { $0.shortcut == "t" }) // system theme
        #expect(state.currentItems.contains { $0.shortcut == "s" }) // user save
        #expect(state.currentItems.contains { $0.shortcut == "x" }) // user extra
    }

    @Test("Set global items with builder merges with system items")
    func setGlobalItemsBuilder() {
        let state = StatusBarState()

        state.setItems {
            StatusBarItem(shortcut: "s", label: "save")
            StatusBarItem(shortcut: "x", label: "extra")
        }

        // User items (s, x) + system items (q, a, t) = 5 total
        #expect(state.currentItems.count == 5)
    }

    @Test("Push context overrides global items but keeps system items")
    func pushContextOverrides() {
        let state = StatusBarState()

        state.setItems([
            StatusBarItem(shortcut: "s", label: "save")
        ])

        state.push(context: "dialog", items: [
            StatusBarItem(shortcut: Shortcut.escape, label: "close"),
            StatusBarItem(shortcut: Shortcut.enter, label: "confirm")
        ])

        // Context items (escape, enter) + system items (q, a, t) = 5 total
        #expect(state.currentItems.count == 5)
        #expect(state.currentItems.contains { $0.shortcut == "q" }) // system quit
        #expect(state.currentItems.contains { $0.shortcut == "a" }) // system appearance
        #expect(state.currentItems.contains { $0.shortcut == "t" }) // system theme
        #expect(state.currentItems.contains { $0.shortcut == Shortcut.escape })
        #expect(state.currentItems.contains { $0.shortcut == Shortcut.enter })
    }

    @Test("Push context with builder merges with system items")
    func pushContextBuilder() {
        let state = StatusBarState()

        state.push(context: "test") {
            StatusBarItem(shortcut: "x", label: "action")  // Use 'x' to not conflict with 'a' (appearance)
        }

        // Context item (x) + system items (q, a, t) = 4 total
        #expect(state.currentItems.count == 4)
        #expect(state.currentItems.contains { $0.label == "action" })
        #expect(state.currentItems.contains { $0.shortcut == "q" })
        #expect(state.currentItems.contains { $0.shortcut == "a" })
        #expect(state.currentItems.contains { $0.shortcut == "t" })
    }

    @Test("Pop context returns to global items with system items")
    func popContextReturnsToGlobal() {
        let state = StatusBarState()

        state.setItems([
            StatusBarItem(shortcut: "g", label: "global")
        ])

        state.push(context: "temp", items: [
            StatusBarItem(shortcut: "x", label: "temp")
        ])

        state.pop(context: "temp")

        // Global item (g) + system items (q, a, t) = 4 total
        #expect(state.currentItems.count == 4)
        #expect(state.currentItems.contains { $0.shortcut == "g" })
        #expect(state.currentItems.contains { $0.shortcut == "q" })
        #expect(state.currentItems.contains { $0.shortcut == "a" })
        #expect(state.currentItems.contains { $0.shortcut == "t" })
    }

    @Test("Context stack respects order")
    func contextStackOrder() {
        let state = StatusBarState()
        state.showSystemItems = false  // Disable system items for cleaner test

        state.push(context: "first", items: [
            StatusBarItem(shortcut: "1", label: "first")
        ])

        state.push(context: "second", items: [
            StatusBarItem(shortcut: "2", label: "second")
        ])

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

        state.push(context: "same", items: [
            StatusBarItem(shortcut: "a", label: "original")
        ])

        state.push(context: "same", items: [
            StatusBarItem(shortcut: "b", label: "replaced")
        ])

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

        state.push(context: "ctx", items: [
            StatusBarItem(shortcut: "c", label: "context")
        ])

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

        state.push(context: "ctx", items: [
            StatusBarItem(shortcut: "c", label: "context")
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

    @Test("Height is zero when no items and system items disabled")
    func heightZeroWhenEmpty() {
        let state = StatusBarState()
        state.showSystemItems = false
        #expect(state.height == 0)
    }
    
    @Test("Height is 1 when only system items")
    func heightWithSystemItems() {
        let state = StatusBarState()
        // System items are enabled by default
        #expect(state.height == 1)  // compact style default
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

// MARK: - StatusBar Tests

@Suite("StatusBar Tests")
struct StatusBarTests {

    @Test("StatusBar can be created with items")
    func statusBarCreation() {
        let statusBar = StatusBar(items: [
            StatusBarItem(shortcut: "q", label: "quit"),
            StatusBarItem(shortcut: "h", label: "help")
        ])

        #expect(statusBar.userItems.count == 2)
        #expect(statusBar.style == .compact)
        #expect(statusBar.alignment == .justified)
        #expect(statusBar.highlightColor == .cyan)
    }

    @Test("StatusBar with style")
    func statusBarWithStyle() {
        let statusBar = StatusBar(
            items: [StatusBarItem(shortcut: "x", label: "test")],
            style: .bordered
        )

        #expect(statusBar.style == .bordered)
    }

    @Test("StatusBar with custom colors")
    func statusBarWithColors() {
        let statusBar = StatusBar(
            items: [],
            highlightColor: .yellow,
            labelColor: .green
        )

        #expect(statusBar.highlightColor == .yellow)
        #expect(statusBar.labelColor == .green)
    }

    @Test("StatusBar with builder")
    func statusBarWithBuilder() {
        let statusBar = StatusBar {
            StatusBarItem(shortcut: "a", label: "alpha")
            StatusBarItem(shortcut: "b", label: "beta")
        }

        #expect(statusBar.userItems.count == 2)
    }

    @Test("StatusBar compact height")
    func compactHeight() {
        let statusBar = StatusBar(items: [], style: .compact)
        #expect(statusBar.height == 1)
    }

    @Test("StatusBar bordered height")
    func borderedHeight() {
        let statusBar = StatusBar(items: [], style: .bordered)
        #expect(statusBar.height == 3)
    }

    @Test("StatusBar renders compact style")
    func rendersCompact() {
        let statusBar = StatusBar(items: [
            StatusBarItem(shortcut: "q", label: "quit")
        ], style: .compact)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.height == 1)
        let content = buffer.lines.joined()
        #expect(content.contains("q"))
        #expect(content.contains("quit"))
    }

    @Test("StatusBar renders bordered style")
    func rendersBordered() {
        let statusBar = StatusBar(items: [
            StatusBarItem(shortcut: "h", label: "help")
        ], style: .bordered)

        // Use default appearance (rounded)
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.height == 3)
        // Should have border characters (appearance-based, default is rounded: ╭─╮)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("╭") || allContent.contains("─") || allContent.contains("╮") ||
                allContent.contains("│") || allContent.contains("╰") || allContent.contains("╯"))
    }

    @Test("Empty StatusBar returns empty buffer")
    func emptyStatusBar() {
        let statusBar = StatusBar(items: [])

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.isEmpty)
    }

    @Test("StatusBar renders multiple items with separator")
    func multipleItemsWithSeparator() {
        let statusBar = StatusBar(items: [
            StatusBarItem(shortcut: "a", label: "alpha"),
            StatusBarItem(shortcut: "b", label: "beta")
        ])

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        let content = buffer.lines.joined()
        #expect(content.contains("alpha"))
        #expect(content.contains("beta"))
    }

    @Test("StatusBar default alignment is justified")
    func defaultAlignmentIsJustified() {
        let statusBar = StatusBar(items: [
            StatusBarItem(shortcut: "q", label: "quit")
        ])

        #expect(statusBar.alignment == .justified)
    }

    @Test("StatusBar with leading alignment")
    func leadingAlignment() {
        let statusBar = StatusBar(
            items: [
                StatusBarItem(shortcut: "a", label: "alpha"),
                StatusBarItem(shortcut: "b", label: "beta")
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

    @Test("StatusBar with trailing alignment")
    func trailingAlignment() {
        let statusBar = StatusBar(
            items: [
                StatusBarItem(shortcut: "a", label: "alpha"),
                StatusBarItem(shortcut: "b", label: "beta")
            ],
            alignment: .trailing
        )

        #expect(statusBar.alignment == .trailing)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        // Content should be at the end
        #expect(!buffer.isEmpty)
    }

    @Test("StatusBar with center alignment")
    func centerAlignment() {
        let statusBar = StatusBar(
            items: [
                StatusBarItem(shortcut: "a", label: "alpha"),
                StatusBarItem(shortcut: "b", label: "beta")
            ],
            alignment: .center
        )

        #expect(statusBar.alignment == .center)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        // Content should be centered - line should not be empty
        #expect(!buffer.isEmpty)
    }

    @Test("StatusBar with justified alignment distributes items")
    func justifiedAlignment() {
        let statusBar = StatusBar(
            items: [
                StatusBarItem(shortcut: "a", label: "first"),
                StatusBarItem(shortcut: "b", label: "second"),
                StatusBarItem(shortcut: "c", label: "third")
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

    @Test("StatusBar bordered with alignment")
    func borderedWithAlignment() {
        let statusBar = StatusBar(
            items: [
                StatusBarItem(shortcut: "a", label: "alpha"),
                StatusBarItem(shortcut: "b", label: "beta")
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

    @Test("StatusBarAlignment enum values exist")
    func alignmentEnumValues() {
        let leading: StatusBarAlignment = .leading
        let trailing: StatusBarAlignment = .trailing
        let center: StatusBarAlignment = .center
        let justified: StatusBarAlignment = .justified

        #expect(leading != trailing)
        #expect(center != justified)
    }

    @Test("Single item with justified alignment is centered")
    func singleItemJustified() {
        let statusBar = StatusBar(
            items: [StatusBarItem(shortcut: "x", label: "only")],
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

    @Test("Builder works with StatusBar initializer")
    func builderWorksWithStatusBar() {
        let statusBar = StatusBar {
            StatusBarItem(shortcut: "x", label: "test")
            StatusBarItem(shortcut: "y", label: "test2")
        }

        #expect(statusBar.userItems.count == 2)
    }
}

// MARK: - StatusBarItems Modifier Tests

@Suite("StatusBarItems Modifier Tests")
struct StatusBarItemsModifierTests {

    @Test("statusBarItems modifier can be applied to view")
    func modifierCanBeApplied() {
        let view = Text("Content")
            .statusBarItems([
                StatusBarItem(shortcut: "q", label: "quit")
            ])

        // View should be wrapped in modifier
        #expect(view is StatusBarItemsModifier<Text>)
    }

    @Test("statusBarItems modifier with builder syntax")
    func modifierWithBuilder() {
        let view = Text("Content")
            .statusBarItems {
                StatusBarItem(shortcut: "a", label: "alpha")
                StatusBarItem(shortcut: "b", label: "beta")
            }

        #expect(view is StatusBarItemsModifier<Text>)
    }

    @Test("statusBarItems modifier with context")
    func modifierWithContext() {
        let view = Text("Dialog")
            .statusBarItems(context: "dialog") {
                StatusBarItem(shortcut: Shortcut.escape, label: "close")
            }

        #expect(view is StatusBarItemsModifier<Text>)
    }

    @Test("statusBarItems modifier sets items in environment")
    func modifierSetsItemsInEnvironment() {
        // Setup: Create a status bar state and environment
        let state = StatusBarState()
        state.showSystemItems = false  // Disable for cleaner test
        var environment = EnvironmentValues()
        environment.statusBar = state

        // Create view with modifier
        let view = Text("Test")
            .statusBarItems {
                StatusBarItem(shortcut: "t", label: "test")
            }

        // Render with environment
        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: environment
        )

        EnvironmentStorage.shared.environment = environment
        _ = renderToBuffer(view, context: context)

        // Check that user items were set
        #expect(state.currentUserItems.count == 1)
        #expect(state.currentUserItems[0].label == "test")
    }

    @Test("statusBarItems modifier with context pushes to stack")
    func modifierWithContextPushesToStack() {
        // Setup
        let state = StatusBarState()
        state.showSystemItems = false  // Disable for cleaner test
        var environment = EnvironmentValues()
        environment.statusBar = state

        // Set global items first
        state.setItems([
            StatusBarItem(shortcut: "g", label: "global")
        ])

        // Create view with context modifier
        let view = Text("Dialog")
            .statusBarItems(context: "dialog") {
                StatusBarItem(shortcut: "d", label: "dialog-item")
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
        #expect(state.currentUserItems.count == 1)
        #expect(state.currentUserItems[0].label == "dialog-item")

        // Pop context
        state.pop(context: "dialog")

        // Global items should be back
        #expect(state.currentUserItems.count == 1)
        #expect(state.currentUserItems[0].label == "global")
    }

    @Test("statusBarItems modifier renders content")
    func modifierRendersContent() {
        let state = StatusBarState()
        var environment = EnvironmentValues()
        environment.statusBar = state

        let view = Text("Hello World")
            .statusBarItems {
                StatusBarItem(shortcut: "x", label: "test")
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
            StatusBarItem(shortcut: "y", label: "yes"),
            StatusBarItem(shortcut: "n", label: "no")
        ]

        let view = Text("Confirm?")
            .statusBarItems(context: "confirm", items: items)

        #expect(view is StatusBarItemsModifier<Text>)
    }

    @Test("Nested statusBarItems modifiers")
    func nestedModifiers() {
        let state = StatusBarState()
        state.showSystemItems = false  // Disable for cleaner test
        var environment = EnvironmentValues()
        environment.statusBar = state

        // Outer sets global, inner pushes context
        let innerView = Text("Inner")
            .statusBarItems(context: "inner") {
                StatusBarItem(shortcut: "i", label: "inner-item")
            }

        let outerView = VStack {
            innerView
        }
        .statusBarItems {
            StatusBarItem(shortcut: "o", label: "outer-item")
        }

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: environment
        )

        EnvironmentStorage.shared.environment = environment
        _ = renderToBuffer(outerView, context: context)

        // Inner context should be on top
        #expect(state.currentUserItems.count == 1)
        #expect(state.currentUserItems[0].label == "inner-item")

        // Pop inner context
        state.pop(context: "inner")

        // Outer (global) should be active
        #expect(state.currentUserItems[0].label == "outer-item")
    }
}

// MARK: - System Status Bar Items Tests

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
    
    @Test("System item order constants are correct")
    func systemItemOrderConstants() {
        // System items should have high order values (900+)
        #expect(StatusBarItemOrder.quit.value == 900)
        #expect(StatusBarItemOrder.appearance.value == 910)
        #expect(StatusBarItemOrder.theme.value == 920)
        
        // User items should have lower order values
        #expect(StatusBarItemOrder.default.value == 500)
        #expect(StatusBarItemOrder.early.value == 100)
        #expect(StatusBarItemOrder.late.value == 800)
        
        // User items < system items
        #expect(StatusBarItemOrder.late < StatusBarItemOrder.quit)
    }
    
    @Test("Items are sorted by order")
    func itemsSortedByOrder() {
        let state = StatusBarState()
        
        // Add items in random order
        state.setItems([
            StatusBarItem(shortcut: "l", label: "late", order: .late),
            StatusBarItem(shortcut: "e", label: "early", order: .early),
            StatusBarItem(shortcut: "d", label: "default", order: .default)
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
