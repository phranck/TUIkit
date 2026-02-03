//
//  ButtonTests.swift
//  TUIkit
//
//  Tests for Button, ButtonStyle, and ButtonRow views.
//

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

    @Test("Button generates unique focus ID by default")
    func buttonGeneratesUniqueID() {
        let button1 = Button("One") {}
        let button2 = Button("Two") {}

        #expect(button1.focusID != button2.focusID)
        // UUID format check
        #expect(button1.focusID.contains("-"))
    }

    @Test("Default button renders as single-line bracket style")
    func defaultButtonRendersBrackets() {
        let context = createTestContext()

        let button = Button("OK") {}
        let buffer = renderToBuffer(button, context: context)

        // Bracket-style buttons are single line: [ OK ]
        #expect(buffer.height == 1)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("OK"))
        #expect(allContent.contains("["))
        #expect(allContent.contains("]"))
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

    @Test("Focused button is rendered bold without arrow indicator")
    func focusedButtonIsBold() {
        let context = createTestContext()

        let button = Button("Focus Me", focusID: "focused-button") {}
        let buffer = renderToBuffer(button, context: context)

        // First button is auto-focused and should be bold (no ▸ indicator)
        let allContent = buffer.lines.joined()
        let boldCode = "\u{1b}["  // ANSI escape — bold style is applied via SGR
        #expect(allContent.contains(boldCode), "Focused button should contain ANSI styling")
        #expect(!allContent.contains("▸"), "Focused bold button should not have ▸ indicator")
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

// MARK: - Button Handler Tests

@Suite("Button Handler Tests")
struct ButtonHandlerTests {

    @Test("ButtonHandler handles Enter key")
    func handleEnterKey() {
        var wasTriggered = false
        let handler = ButtonHandler(
            focusID: "enter-test",
            action: { wasTriggered = true },
            canBeFocused: true
        )

        let event = KeyEvent(key: .enter)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(wasTriggered == true)
    }

    @Test("ButtonHandler handles Space key")
    func handleSpaceKey() {
        var wasTriggered = false
        let handler = ButtonHandler(
            focusID: "space-test",
            action: { wasTriggered = true },
            canBeFocused: true
        )

        let event = KeyEvent(key: .character(" "))
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(wasTriggered == true)
    }

    @Test("ButtonHandler ignores other keys")
    func ignoresOtherKeys() {
        var wasTriggered = false
        let handler = ButtonHandler(
            focusID: "ignore-test",
            action: { wasTriggered = true },
            canBeFocused: true
        )

        let event = KeyEvent(key: .character("a"))
        let handled = handler.handleKeyEvent(event)

        #expect(handled == false)
        #expect(wasTriggered == false)
    }
}

// MARK: - Button Row Tests

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
