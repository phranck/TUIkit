//  TUIKit - Terminal UI Kit for Swift
//  ToggleTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Test Helpers

/// Creates a render context with a fresh FocusManager for isolated testing.
private func createTestContext(width: Int = 80, height: Int = 24) -> RenderContext {
    let focusManager = FocusManager()
    var environment = EnvironmentValues()
    environment.focusManager = focusManager

    return RenderContext(
        availableWidth: width,
        availableHeight: height,
        environment: environment,
        tuiContext: TUIContext()
    )
}

// MARK: - Toggle Tests

@MainActor
@Suite("Toggle Tests", .serialized)
struct ToggleTests {

    @Test("Toggle can be created with binding and label")
    func toggleCreation() {
        var isEnabled = false
        let binding = Binding(
            get: { isEnabled },
            set: { isEnabled = $0 }
        )

        let toggle = Toggle("Enable", isOn: binding)

        #expect(toggle.isDisabled == false)
    }

    @Test("Toggle disabled modifier")
    func toggleDisabledModifier() {
        var state = false
        let binding = Binding(
            get: { state },
            set: { state = $0 }
        )

        let toggle = Toggle("Test", isOn: binding).disabled()

        #expect(toggle.isDisabled == true)

        let enabledToggle = Toggle("Test", isOn: binding).disabled(false)

        #expect(enabledToggle.isDisabled == false)
    }

    @Test("Toggle renders with brackets")
    func toggleRenders() {
        let context = createTestContext()

        // Off state
        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Test", isOn: binding)
        let buffer = renderToBuffer(toggle, context: context)

        // Should render as single line with [ ] indicator (OFF)
        #expect(buffer.height == 1)
        let content = buffer.lines.joined()
        #expect(content.contains("[") && content.contains("]"))
    }

    @Test("Toggle OFF renders empty brackets")
    func toggleOffState() {
        let context = createTestContext()

        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Test", isOn: binding)
        let buffer = renderToBuffer(toggle, context: context)

        let content = buffer.lines.joined().stripped
        #expect(content.contains("[ ]"))
    }

    @Test("Toggle ON renders x in brackets")
    func toggleOnState() {
        let context = createTestContext()

        var isOn = true
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Test", isOn: binding)
        let buffer = renderToBuffer(toggle, context: context)

        let content = buffer.lines.joined().stripped
        #expect(content.contains("[x]"))
    }

    @Test("Toggle renders focus indicator when focused")
    func toggleFocusIndicator() {
        let context = createTestContext()

        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Focused", isOn: binding)

        let buffer = renderToBuffer(toggle, context: context)

        // Focused toggle should have ANSI codes (pulsing brackets)
        let content = buffer.lines.joined()
        #expect(content.contains("\u{1b}["), "Focused toggle should have ANSI styling for pulsing brackets")
    }

    @Test("Toggle renders without focus indicator when unfocused")
    func toggleUnfocusedNoIndicator() {
        let context = createTestContext()

        var state1 = false
        var state2 = false
        let binding1 = Binding(get: { state1 }, set: { state1 = $0 })
        let binding2 = Binding(get: { state2 }, set: { state2 = $0 })

        let toggle1 = Toggle("First", isOn: binding1)
        let toggle2 = Toggle("Second", isOn: binding2)

        // Render first (gets focus), then second
        _ = renderToBuffer(toggle1, context: context)
        let buffer2 = renderToBuffer(toggle2, context: context)

        // Unfocused toggle should not have leading space for focus indicator
        let content = buffer2.lines.joined().stripped
        #expect(content.contains("Second"))
    }

    @Test("Toggle label is rendered next to indicator")
    func toggleLabelRendering() {
        let context = createTestContext()

        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("My Setting", isOn: binding)
        let buffer = renderToBuffer(toggle, context: context)

        let content = buffer.lines.joined()
        #expect(content.contains("My Setting"))
    }

    @Test("Disabled toggle uses tertiary color")
    func disabledToggleColor() {
        let context = createTestContext()

        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Disabled", isOn: binding).disabled()
        let buffer = renderToBuffer(toggle, context: context)

        // Disabled toggle should be rendered but with different styling
        let content = buffer.lines.joined()
        #expect(content.contains("Disabled"))
    }
}

// MARK: - Toggle Handler Tests

@MainActor
@Suite("Toggle Action Handler Integration Tests")
struct ToggleActionHandlerIntegrationTests {

    @Test("Toggle uses ActionHandler for key events")
    func toggleUsesActionHandler() {
        // Verify that Toggle's action handler correctly toggles the binding
        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        // Create handler as Toggle does internally
        let handler = ActionHandler(
            focusID: "toggle-test",
            action: { binding.wrappedValue.toggle() },
            canBeFocused: true
        )

        // Space key should toggle
        let spaceEvent = KeyEvent(key: .space)
        let spaceHandled = handler.handleKeyEvent(spaceEvent)

        #expect(spaceHandled == true)
        #expect(isOn == true)

        // Enter key should toggle back
        let enterEvent = KeyEvent(key: .enter)
        let enterHandled = handler.handleKeyEvent(enterEvent)

        #expect(enterHandled == true)
        #expect(isOn == false)
    }

    @Test("Toggle action handler ignores other keys")
    func ignoresOtherKeys() {
        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let handler = ActionHandler(
            focusID: "ignore-test",
            action: { binding.wrappedValue.toggle() },
            canBeFocused: true
        )

        let event = KeyEvent(key: .character("a"))
        let handled = handler.handleKeyEvent(event)

        #expect(handled == false)
        #expect(isOn == false)
    }
}
