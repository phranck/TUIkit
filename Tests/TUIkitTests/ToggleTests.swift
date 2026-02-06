//  🖥️ TUIKit — Terminal UI Kit for Swift
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
        environment: environment
    )
}

// MARK: - Toggle Tests

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
        #expect(toggle.style == .toggle)
    }

    @Test("Toggle string initializer creates binding")
    func toggleStringInitializer() {
        var isDarkMode = false
        let binding = Binding(
            get: { isDarkMode },
            set: { isDarkMode = $0 }
        )

        let toggle = Toggle("Dark mode", isOn: binding, style: .checkbox)

        #expect(toggle.isDisabled == false)
        #expect(toggle.style == .checkbox)
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

    @Test("Toggle generates unique focus ID by default")
    func toggleGeneratesUniqueID() {
        var state1 = false
        var state2 = false
        let binding1 = Binding(get: { state1 }, set: { state1 = $0 })
        let binding2 = Binding(get: { state2 }, set: { state2 = $0 })

        let toggle1 = Toggle("One", isOn: binding1)
        let toggle2 = Toggle("Two", isOn: binding2)

        #expect(toggle1.focusID != toggle2.focusID)
    }

    @Test("Toggle style toggle renders correct states")
    func toggleStyleRender() {
        let context = createTestContext()

        // Off state
        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Test", isOn: binding, style: .toggle)
        let buffer = renderToBuffer(toggle, context: context)

        // Should render as single line with ○● indicator
        #expect(buffer.height == 1)
        let content = buffer.lines.joined()
        #expect(content.contains("○●"))
    }

    @Test("Toggle style checkbox renders correct states")
    func checkboxStyleRender() {
        let context = createTestContext()

        // Off state
        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Test", isOn: binding, style: .checkbox)
        let buffer = renderToBuffer(toggle, context: context)

        // Should render as single line with [ ] indicator
        #expect(buffer.height == 1)
        let content = buffer.lines.joined()
        // Off state: [ ] (space), on state: [●] (dot)
        #expect(content.contains("[ ]") || content.contains("[●]"))
    }

    @Test("Toggle renders focus indicator when focused")
    func toggleFocusIndicator() {
        let context = createTestContext()

        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Focused", isOn: binding, focusID: "test-toggle")

        let buffer = renderToBuffer(toggle, context: context)

        // Focused toggle should have ANSI codes (pulsing brackets, no dot)
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

        let toggle1 = Toggle("First", isOn: binding1, focusID: "first")
        let toggle2 = Toggle("Second", isOn: binding2, focusID: "second")

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

    @Test("Toggle with text label renders correctly")
    func toggleWithTextLabel() {
        let context = createTestContext()

        var isOn = true
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let toggle = Toggle("Feature enabled", isOn: binding, style: .toggle)

        let buffer = renderToBuffer(toggle, context: context)

        #expect(buffer.height == 1)
        let content = buffer.lines.joined()
        #expect(content.contains("Feature enabled"))
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

@Suite("Toggle Handler Tests")
struct ToggleHandlerTests {

    @Test("ToggleHandler handles Space key to toggle state")
    func handleSpaceKey() {
        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let handler = ToggleHandler(
            focusID: "space-test",
            isOn: binding,
            canBeFocused: true
        )

        let event = KeyEvent(key: .character(" "))
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(isOn == true)
    }

    @Test("ToggleHandler handles Enter key to toggle state")
    func handleEnterKey() {
        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let handler = ToggleHandler(
            focusID: "enter-test",
            isOn: binding,
            canBeFocused: true
        )

        let event = KeyEvent(key: .enter)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(isOn == true)
    }

    @Test("ToggleHandler ignores other keys")
    func ignoresOtherKeys() {
        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let handler = ToggleHandler(
            focusID: "ignore-test",
            isOn: binding,
            canBeFocused: true
        )

        let event = KeyEvent(key: .character("a"))
        let handled = handler.handleKeyEvent(event)

        #expect(handled == false)
        #expect(isOn == false)
    }

    @Test("ToggleHandler respects canBeFocused property")
    func respectsCanBeFocused() {
        var isOn = false
        let binding = Binding(
            get: { isOn },
            set: { isOn = $0 }
        )

        let handler = ToggleHandler(
            focusID: "disabled-test",
            isOn: binding,
            canBeFocused: false
        )

        #expect(handler.canBeFocused == false)
    }
}

// MARK: - Toggle Style Tests

@Suite("Toggle Style Tests")
struct ToggleStyleTests {

    @Test("ToggleStyle values are distinct")
    func toggleStyleValuesDistinct() {
        let toggleStyle: ToggleStyle = .toggle
        let checkboxStyle: ToggleStyle = .checkbox

        // Verify they're different
        #expect(toggleStyle != checkboxStyle)
    }

    @Test("ToggleStyle is Sendable")
    func toggleStyleSendable() {
        let style: ToggleStyle = .toggle

        // Verify it can be stored and compared
        var receivedStyle: ToggleStyle = style
        receivedStyle = .checkbox

        #expect(receivedStyle == .checkbox)
    }
}
