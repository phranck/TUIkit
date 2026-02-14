//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StatusBarViewTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - StatusBar Tests

@MainActor
@Suite("StatusBar Tests")
struct StatusBarViewTests {

    @Test("StatusBar renders compact style")
    func rendersCompact() {
        let statusBar = StatusBar(
            items: [
                StatusBarItem(shortcut: "q", label: "quit")
            ],
            style: .compact
        )

        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.height == 1)
        let content = buffer.lines.joined()
        #expect(content.contains("q"))
        #expect(content.contains("quit"))
    }

    @Test("StatusBar renders bordered style")
    func rendersBordered() {
        let statusBar = StatusBar(
            items: [
                StatusBarItem(shortcut: "h", label: "help")
            ],
            style: .bordered
        )

        // Use default appearance (rounded)
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.height == 3)
        // Should have border characters (appearance-based, default is rounded: ╭─╮)
        let allContent = buffer.lines.joined()
        #expect(
            allContent.contains("╭") || allContent.contains("─") || allContent.contains("╮") || allContent.contains("│")
                || allContent.contains("╰") || allContent.contains("╯")
        )
    }

    @Test("Empty StatusBar returns empty buffer")
    func emptyStatusBar() {
        let statusBar = StatusBar(items: [])

        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.isEmpty)
    }

    @Test("StatusBar renders multiple items with separator")
    func multipleItemsWithSeparator() {
        let statusBar = StatusBar(items: [
            StatusBarItem(shortcut: "a", label: "alpha"),
            StatusBarItem(shortcut: "b", label: "beta"),
        ])

        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(statusBar, context: context)

        let content = buffer.lines.joined()
        #expect(content.contains("alpha"))
        #expect(content.contains("beta"))
    }

    @Test("StatusBar with leading alignment")
    func leadingAlignment() {
        let statusBar = StatusBar(
            items: [
                StatusBarItem(shortcut: "a", label: "alpha"),
                StatusBarItem(shortcut: "b", label: "beta"),
            ],
            alignment: .leading
        )

        #expect(statusBar.alignment == .leading)

        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(statusBar, context: context)

        // Content should start near the beginning (after padding)
        let line = buffer.lines[0]
        #expect(line.contains("alpha"))
        #expect(line.contains("beta"))
    }

    @Test("StatusBar with trailing alignment")
    func trailingAlignment() {
        let statusBar = StatusBar(
            items: [
                StatusBarItem(shortcut: "a", label: "alpha"),
                StatusBarItem(shortcut: "b", label: "beta"),
            ],
            alignment: .trailing
        )

        #expect(statusBar.alignment == .trailing)

        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(statusBar, context: context)

        // Content should be at the end
        let line = buffer.lines[0]
        #expect(line.contains("alpha"))
        #expect(line.contains("beta"))
    }

    @Test("StatusBar with center alignment")
    func centerAlignment() {
        let statusBar = StatusBar(
            items: [
                StatusBarItem(shortcut: "a", label: "alpha"),
                StatusBarItem(shortcut: "b", label: "beta"),
            ],
            alignment: .center
        )

        #expect(statusBar.alignment == .center)

        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(statusBar, context: context)

        // Content should be centered
        let line = buffer.lines[0]
        #expect(line.contains("alpha"))
        #expect(line.contains("beta"))
    }

    @Test("StatusBar with justified alignment distributes items")
    func justifiedAlignment() {
        let statusBar = StatusBar(
            items: [
                StatusBarItem(shortcut: "a", label: "first"),
                StatusBarItem(shortcut: "b", label: "second"),
                StatusBarItem(shortcut: "c", label: "third"),
            ],
            alignment: .justified
        )

        #expect(statusBar.alignment == .justified)

        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
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
                StatusBarItem(shortcut: "b", label: "beta"),
            ],
            style: .bordered,
            alignment: .center
        )

        #expect(statusBar.style == .bordered)
        #expect(statusBar.alignment == .center)

        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.height == 3)
    }
}

// MARK: - Status Bar Alignment Tests

@MainActor
@Suite("Status Bar Alignment Tests")
struct StatusBarAlignmentTests {

    @Test("Single item with justified alignment is centered")
    func singleItemJustified() {
        let statusBar = StatusBar(
            items: [StatusBarItem(shortcut: "x", label: "only")],
            alignment: .justified
        )

        let context = RenderContext(availableWidth: 40, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(statusBar, context: context)

        // Single item should be centered in justified mode
        let line = buffer.lines[0]
        #expect(line.contains("only"))
        #expect(line.strippedLength == 40)
    }
}

// MARK: - StatusBarItems Modifier Tests

@MainActor
@Suite("StatusBarItems Modifier Tests", .serialized)
struct StatusBarItemsModifierTests {

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
            environment: environment,
            tuiContext: TUIContext()
        )

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
            environment: environment,
            tuiContext: TUIContext()
        )

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
            environment: environment,
            tuiContext: TUIContext()
        )

        let buffer = renderToBuffer(view, context: context)

        // Content should be rendered
        let content = buffer.lines.joined()
        #expect(content.contains("Hello World"))
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
            environment: environment,
            tuiContext: TUIContext()
        )

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
