//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ButtonTests.swift
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

// MARK: - Button Tests

@MainActor
@Suite("Button Tests", .serialized)
struct ButtonTests {

    @Test("Button can be created with label and action")
    func buttonCreation() {
        var wasPressed = false
        let button = Button("Click Me") {
            wasPressed = true
        }

        #expect(button.label == "Click Me")
        #expect(button.isDisabled == false)
        button.action()
        #expect(wasPressed == true)
    }

    @Test("Button disabled modifier")
    func buttonDisabledModifier() {
        let button = Button("Test") {}.disabled()
        #expect(button.isDisabled == true)

        let enabledButton = Button("Test") {}.disabled(false)
        #expect(enabledButton.isDisabled == false)
    }

    @Test("Button focusID defaults to nil (auto-generated during rendering)")
    func buttonGeneratesUniqueID() {
        let button1 = Button("One") {}
        let button2 = Button("Two") {}

        // FocusID is now nil by default, allowing auto-generation from context.identity.path
        // during rendering via FocusRegistration.persistFocusID()
        #expect(button1.focusID == nil)
        #expect(button2.focusID == nil)
    }

    @Test("Default button renders as single-line bracket style")
    func defaultButtonRendersBrackets() {
        let context = createTestContext()

        let button = Button("OK") {}
        let buffer = renderToBuffer(button, context: context)

        // Cap-style buttons are single line: ▐ OK ▌
        #expect(buffer.height == 1)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("OK"))
        #expect(allContent.stripped.contains("\u{2590}"))
        #expect(allContent.stripped.contains("\u{258C}"))
    }

    @Test("Default button is single line height")
    func defaultButtonSingleLine() {
        let context = createTestContext()

        let button = Button("Test", style: .default) {}
        let buffer = renderToBuffer(button, context: context)

        #expect(buffer.height == 1)
    }

    @Test("Plain button has single line without brackets")
    func plainButtonSingleLine() {
        let context = createTestContext()

        let button = Button("Test", style: .plain) {}
        let buffer = renderToBuffer(button, context: context)

        #expect(buffer.height == 1)
        // Check visible text (stripped of ANSI codes) has no brackets
        let visibleContent = buffer.lines.joined().stripped
        #expect(!visibleContent.contains("["))
        #expect(!visibleContent.contains("]"))
    }

    @Test("Focused button has accent-colored brackets")
    func focusedButtonHasAccentBrackets() {
        let context = createTestContext()

        let button = Button("Focus Me") {}.focusID("focused-button")
        let buffer = renderToBuffer(button, context: context)

        // First button is auto-focused — caps should be styled (contain ANSI codes)
        let allContent = buffer.lines.joined()
        #expect(allContent.stripped.contains("\u{2590}"), "Button should have opening cap")
        #expect(allContent.stripped.contains("\u{258C}"), "Button should have closing cap")
        #expect(allContent.contains("\u{1b}["), "Focused button should have ANSI styling")
    }

    @Test("Unfocused button has border-colored brackets")
    func unfocusedButtonHasBorderBrackets() {
        let context = createTestContext()

        // Create two buttons — second one will be unfocused
        let button1 = Button("First") {}.focusID("first")
        let button2 = Button("Second") {}.focusID("second")

        // Render first to register it (it gets focus)
        _ = renderToBuffer(button1, context: context)
        let buffer2 = renderToBuffer(button2, context: context)

        // Second button is not focused — should still have caps with styling
        let allContent = buffer2.lines.joined()
        #expect(allContent.stripped.contains("\u{2590}"), "Unfocused button should have opening cap")
        #expect(allContent.stripped.contains("\u{258C}"), "Unfocused button should have closing cap")
    }

    @Test("Destructive button uses palette error color, not hardcoded red")
    func destructiveButtonUsesPaletteColor() {
        let context = createTestContext()

        let button = Button("Delete", style: .destructive) {}
        let buffer = renderToBuffer(button, context: context)

        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Delete"))
        // Should contain ANSI color codes (resolved from palette.error)
        #expect(allContent.contains("\u{1b}["))
    }

    @Test("Primary button is bold")
    func primaryButtonIsBold() {
        let context = createTestContext()

        let button = Button("Submit", style: .primary) {}
        let buffer = renderToBuffer(button, context: context)

        let allContent = buffer.lines.joined()
        // Primary style sets isBold = true, rendered as bold ANSI
        #expect(allContent.contains("\u{1b}[1;"))
    }
}

// MARK: - Action Handler Tests

@MainActor
@Suite("Action Handler Tests")
struct ActionHandlerTests {

    @Test("ActionHandler handles Enter key")
    func handleEnterKey() {
        var wasTriggered = false
        let handler = ActionHandler(
            focusID: "enter-test",
            action: { wasTriggered = true },
            canBeFocused: true
        )

        let event = KeyEvent(key: .enter)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(wasTriggered == true)
    }

    @Test("ActionHandler handles Space key")
    func handleSpaceKey() {
        var wasTriggered = false
        let handler = ActionHandler(
            focusID: "space-test",
            action: { wasTriggered = true },
            canBeFocused: true
        )

        let event = KeyEvent(key: .space)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(wasTriggered == true)
    }

    @Test("ActionHandler ignores other keys")
    func ignoresOtherKeys() {
        var wasTriggered = false
        let handler = ActionHandler(
            focusID: "ignore-test",
            action: { wasTriggered = true },
            canBeFocused: true
        )

        let event = KeyEvent(key: .character("a"))
        let handled = handler.handleKeyEvent(event)

        #expect(handled == false)
        #expect(wasTriggered == false)
    }

    @Test("ActionHandler respects custom trigger keys")
    func customTriggerKeys() {
        var wasTriggered = false
        let handler = ActionHandler(
            focusID: "custom-test",
            action: { wasTriggered = true },
            canBeFocused: true,
            triggerKeys: [Key.enter]  // Only Enter, not Space
        )

        // Space should not trigger
        let spaceEvent = KeyEvent(key: .character(" "))
        let spaceHandled = handler.handleKeyEvent(spaceEvent)
        #expect(spaceHandled == false)
        #expect(wasTriggered == false)

        // Enter should trigger
        let enterEvent = KeyEvent(key: .enter)
        let enterHandled = handler.handleKeyEvent(enterEvent)
        #expect(enterHandled == true)
        #expect(wasTriggered == true)
    }
}

// MARK: - Button Row Tests

@MainActor
@Suite("Button Row Tests")
struct ButtonRowTests {

    @Test("ButtonRow can be created with buttons")
    func buttonRowCreation() {
        let context = createTestContext()

        let row = ButtonRow {
            Button("Cancel") {}
            Button("OK") {}
        }

        let buffer = renderToBuffer(row, context: context)

        // Bracket-style buttons are single line
        #expect(buffer.height == 1)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Cancel"))
        #expect(allContent.contains("OK"))
    }

    @Test("ButtonRow with custom spacing")
    func buttonRowSpacing() {
        let context = createTestContext()

        let row = ButtonRow(spacing: 5) {
            Button("A", style: .plain) {}
            Button("B", style: .plain) {}
        }

        let buffer = renderToBuffer(row, context: context)

        // Both buttons should be present
        #expect(buffer.height == 1) // plain buttons without border
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("A"))
        #expect(allContent.contains("B"))
    }

    @Test("Empty ButtonRow returns empty buffer")
    func emptyButtonRow() {
        let row = ButtonRow {}
        let context = createTestContext()

        let buffer = renderToBuffer(row, context: context)

        #expect(buffer.isEmpty)
    }

    @Test("ButtonRow renders buttons horizontally")
    func buttonRowHorizontal() {
        let context = createTestContext()

        let row = ButtonRow {
            Button("First", style: .plain) {}
            Button("Second", style: .plain) {}
        }

        let buffer = renderToBuffer(row, context: context)

        // Should have same number of lines (horizontal layout)
        // Plain buttons are single line, so the row should be single line
        #expect(buffer.height == 1)
    }

    @Test("ButtonRow with mixed styles has uniform height")
    func buttonRowUniformHeight() {
        let context = createTestContext()

        let row = ButtonRow {
            Button("Default") {}
            Button("Plain", style: .plain) {}
        }

        let buffer = renderToBuffer(row, context: context)

        // Both are now single line (brackets and plain)
        #expect(buffer.height == 1)
    }
}

// MARK: - Button Row Builder Tests

@MainActor
@Suite("Button Row Builder Tests")
struct ButtonRowBuilderTests {

    @Test("ButtonRowBuilder builds array of buttons")
    func builderCreatesArray() {
        let buttons = ButtonRowBuilder.buildBlock(
            Button("A") {},
            Button("B") {},
            Button("C") {}
        )

        #expect(buttons.count == 3)
    }

    @Test("ButtonRowBuilder handles optional")
    func builderHandlesOptional() {
        let buttons: [Button]? = nil
        let result = ButtonRowBuilder.buildOptional(buttons)

        #expect(result.isEmpty)

        let someButtons: [Button]? = [Button("Test") {}]
        let result2 = ButtonRowBuilder.buildOptional(someButtons)

        #expect(result2.count == 1)
    }

    @Test("ButtonRowBuilder handles either first")
    func builderHandlesEitherFirst() {
        let buttons = [Button("First") {}]
        let result = ButtonRowBuilder.buildEither(first: buttons)

        #expect(result.count == 1)
        #expect(result[0].label == "First")
    }

    @Test("ButtonRowBuilder handles either second")
    func builderHandlesEitherSecond() {
        let buttons = [Button("Second") {}]
        let result = ButtonRowBuilder.buildEither(second: buttons)

        #expect(result.count == 1)
        #expect(result[0].label == "Second")
    }

    @Test("ButtonRowBuilder handles array")
    func builderHandlesArray() {
        let groups: [[Button]] = [
            [Button("A") {}],
            [Button("B") {}, Button("C") {}],
        ]
        let result = ButtonRowBuilder.buildArray(groups)

        #expect(result.count == 3)
    }
}
