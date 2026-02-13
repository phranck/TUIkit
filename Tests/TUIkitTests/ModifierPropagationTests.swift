//  TUIKit - Terminal UI Kit for Swift
//  ModifierPropagationTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Test Helpers

/// Creates a default render context for testing.
@MainActor
private func testContext(width: Int = 40, height: Int = 24) -> RenderContext {
    RenderContext(availableWidth: width, availableHeight: height)
}

// MARK: - Modifier Propagation Tests

@MainActor
@Suite("Modifier Propagation Tests")
struct ModifierPropagationTests {

    // MARK: - Environment Propagation

    @Test("foregroundStyle propagates through View hierarchy")
    func foregroundStylePropagates() {
        // Create a view hierarchy with foregroundStyle applied at top level
        let view = VStack {
            Text("Hello")
            Text("World")
        }
        .foregroundStyle(.red)

        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        // Both lines should contain red ANSI code
        let redCode = "\u{1B}[31m"
        #expect(buffer.lines[0].contains(redCode), "First text should have red color")
        #expect(buffer.lines[1].contains(redCode), "Second text should have red color")
    }

    @Test("foregroundStyle propagates to nested containers")
    func foregroundStylePropagatesNested() {
        let view = VStack {
            HStack {
                Text("A")
                Text("B")
            }
        }
        .foregroundStyle(.green)

        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        // Content should have green color
        let greenCode = "\u{1B}[32m"
        #expect(buffer.lines[0].contains(greenCode), "Nested content should have green color")
    }

    @Test("Child foregroundStyle overrides parent")
    func childForegroundStyleOverrides() {
        let view = VStack {
            Text("Red")
            Text("Blue").foregroundStyle(.blue)
        }
        .foregroundStyle(.red)

        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let redCode = "\u{1B}[31m"
        let blueCode = "\u{1B}[34m"

        #expect(buffer.lines[0].contains(redCode), "First text should be red")
        #expect(buffer.lines[1].contains(blueCode), "Second text should be blue (overridden)")
    }

    // MARK: - Button Modifier Propagation

    @Test("Button renders with body: some View pattern")
    func buttonRendersCorrectly() {
        var actionCalled = false
        let button = Button("Test") {
            actionCalled = true
        }

        let context = testContext()
        let buffer = renderToBuffer(button, context: context)

        // Button should render with caps
        #expect(buffer.lines[0].stripped.contains("\u{2590}"))
        #expect(buffer.lines[0].stripped.contains("Test"))
        #expect(buffer.lines[0].stripped.contains("\u{258C}"))
        #expect(!actionCalled, "Action should not be called during render")
    }

    @Test("Button disabled state propagates")
    func buttonDisabledStatePropagates() {
        let button = Button("Disabled") {}
            .disabled(true)

        let context = testContext()
        let buffer = renderToBuffer(button, context: context)

        // Disabled button should render (with dimmed styling)
        #expect(buffer.lines[0].stripped.contains("Disabled"))
    }

    // MARK: - Toggle Modifier Propagation

    @Test("Toggle renders with body: some View pattern")
    func toggleRendersCorrectly() {
        var isOn = false
        let toggle = Toggle("Enable", isOn: Binding(get: { isOn }, set: { isOn = $0 }))

        let context = testContext()
        let buffer = renderToBuffer(toggle, context: context)

        // Toggle should render with brackets and label
        #expect(buffer.lines[0].stripped.contains("[") && buffer.lines[0].stripped.contains("]"))
        #expect(buffer.lines[0].contains("Enable"))
    }

    @Test("Toggle disabled state propagates")
    func toggleDisabledStatePropagates() {
        var isOn = true
        let toggle = Toggle("Disabled Toggle", isOn: Binding(get: { isOn }, set: { isOn = $0 }))
            .disabled(true)

        let context = testContext()
        let buffer = renderToBuffer(toggle, context: context)

        #expect(buffer.lines[0].contains("Disabled Toggle"))
    }

    // MARK: - Menu Modifier Propagation

    @Test("Menu renders with body: some View pattern")
    func menuRendersCorrectly() {
        let menu = Menu(
            title: "Test Menu",
            items: [
                MenuItem(label: "Item 1"),
                MenuItem(label: "Item 2")
            ]
        )

        let context = testContext()
        let buffer = renderToBuffer(menu, context: context)

        // Menu should render with border and items
        #expect(buffer.height > 2, "Menu should have multiple lines")
        #expect(buffer.lines.joined().contains("Test Menu"))
        #expect(buffer.lines.joined().contains("Item 1"))
        #expect(buffer.lines.joined().contains("Item 2"))
    }

    // MARK: - RadioButtonGroup Modifier Propagation

    @Test("RadioButtonGroup renders with body: some View pattern")
    func radioButtonGroupRendersCorrectly() {
        var selection = "a"
        let group = RadioButtonGroup(
            selection: Binding(get: { selection }, set: { selection = $0 })
        ) {
            RadioButtonItem("a", "Option A")
            RadioButtonItem("b", "Option B")
        }

        let context = testContext()
        let buffer = renderToBuffer(group, context: context)

        // RadioButtonGroup should render items vertically
        #expect(buffer.height == 2, "Should have 2 lines for 2 items")
        #expect(buffer.lines[0].contains("Option A"))
        #expect(buffer.lines[1].contains("Option B"))
    }

    @Test("RadioButtonGroup disabled state propagates")
    func radioButtonGroupDisabledStatePropagates() {
        var selection = "a"
        let group = RadioButtonGroup(
            selection: Binding(get: { selection }, set: { selection = $0 })
        ) {
            RadioButtonItem("a", "Option A")
        }
        .disabled(true)

        let context = testContext()
        let buffer = renderToBuffer(group, context: context)

        #expect(buffer.lines[0].contains("Option A"))
    }

    // MARK: - Complex Hierarchy Tests

    @Test("Modifiers propagate through complex hierarchy")
    func modifiersPropagateComplexHierarchy() {
        let view = VStack {
            Text("Title").bold()
            HStack {
                Text("Left")
                Text("Right")
            }
            Text("Footer")
        }
        .foregroundStyle(.cyan)

        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        // All text should have cyan color (36m, possibly with bold prefix 1;)
        for line in buffer.lines where !line.stripped.isEmpty {
            #expect(line.contains("36m"), "All non-empty lines should have cyan color code: \(line.stripped)")
        }
    }

    @Test("Padding modifier works with refactored views")
    func paddingWorksWithRefactoredViews() {
        var actionCalled = false
        let button = Button("Padded") { actionCalled = true }
            .padding(2)

        let context = testContext()
        let buffer = renderToBuffer(button, context: context)

        // Should have padding lines
        #expect(buffer.height >= 3, "Should have top padding + content + bottom padding")
        #expect(!actionCalled)
    }

    @Test("Border modifier works with refactored views")
    func borderWorksWithRefactoredViews() {
        var isOn = false
        let toggle = Toggle("Bordered", isOn: Binding(get: { isOn }, set: { isOn = $0 }))
            .border(.line)

        let context = testContext()
        let buffer = renderToBuffer(toggle, context: context)

        // Should have border
        #expect(buffer.height == 3, "Should have top border + content + bottom border")
        #expect(buffer.lines[0].stripped.contains("\u{250C}") || buffer.lines[0].stripped.contains("\u{2500}"))
    }
}
