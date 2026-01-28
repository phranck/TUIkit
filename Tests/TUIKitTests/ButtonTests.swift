//
//  ButtonTests.swift
//  TUIKit
//
//  Tests for Button, ButtonStyle, and ButtonRow views.
//

import Testing
@testable import TUIKit

// MARK: - Test Helpers

/// Creates a render context with a fresh FocusManager for isolated testing.
private func createTestContext(width: Int = 80, height: Int = 24) -> RenderContext {
    let focusManager = FocusManager()
    var environment = EnvironmentValues()
    environment.focusManager = focusManager
    EnvironmentStorage.shared.environment = environment

    return RenderContext(
        availableWidth: width,
        availableHeight: height,
        environment: environment
    )
}

/// Cleans up the environment after a test.
private func cleanupEnvironment() {
    EnvironmentStorage.shared.reset()
}

// MARK: - Button Style Tests

@Suite("Button Style Tests")
struct ButtonStyleTests {

    @Test("Default button style")
    func defaultStyle() {
        let style = ButtonStyle.default
        #expect(style.borderStyle == .rounded)
        #expect(style.horizontalPadding == 2)
        #expect(style.isBold == false)
    }

    @Test("Primary button style")
    func primaryStyle() {
        let style = ButtonStyle.primary
        #expect(style.foregroundColor == .cyan)
        #expect(style.borderColor == .cyan)
        #expect(style.isBold == true)
    }

    @Test("Destructive button style")
    func destructiveStyle() {
        let style = ButtonStyle.destructive
        #expect(style.foregroundColor == .red)
        #expect(style.borderColor == .red)
    }

    @Test("Success button style")
    func successStyle() {
        let style = ButtonStyle.success
        #expect(style.foregroundColor == .green)
        #expect(style.borderColor == .green)
    }

    @Test("Plain button style has no border")
    func plainStyle() {
        let style = ButtonStyle.plain
        #expect(style.borderStyle == nil)
        #expect(style.horizontalPadding == 0)
    }

    @Test("Custom button style")
    func customStyle() {
        let style = ButtonStyle(
            foregroundColor: Color.yellow,
            backgroundColor: Color.blue,
            borderStyle: .line,
            borderColor: Color.magenta,
            isBold: true,
            horizontalPadding: 4
        )
        #expect(style.foregroundColor == .yellow)
        #expect(style.backgroundColor == .blue)
        #expect(style.borderStyle == .line)
        #expect(style.borderColor == .magenta)
        #expect(style.isBold == true)
        #expect(style.horizontalPadding == 4)
    }
}

// MARK: - Button Tests

@Suite("Button Tests")
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

    @Test("Button with custom style")
    func buttonWithStyle() {
        let button = Button("Delete", style: .destructive) {}
        #expect(button.style.foregroundColor == .red)
        #expect(button.style.borderColor == .red)
    }

    @Test("Button with custom focus ID")
    func buttonWithFocusID() {
        let button = Button("OK", focusID: "ok-button") {}
        #expect(button.focusID == "ok-button")
    }

    @Test("Disabled button")
    func disabledButton() {
        let button = Button("Disabled", isDisabled: true) {}
        #expect(button.isDisabled == true)
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

    @Test("Button renders to buffer")
    func buttonRenders() {
        let context = createTestContext()
        defer { cleanupEnvironment() }

        let button = Button("OK") {}
        let buffer = renderToBuffer(button, context: context)

        #expect(!buffer.isEmpty)
        #expect(buffer.height >= 1)

        // Should contain the label
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("OK"))
    }

    @Test("Button with border has proper height")
    func buttonWithBorderHeight() {
        let context = createTestContext()
        defer { cleanupEnvironment() }

        let button = Button("Test", style: .default) {}
        let buffer = renderToBuffer(button, context: context)

        // With rounded border: top + content + bottom = 3 lines
        #expect(buffer.height == 3)
    }

    @Test("Plain button has single line")
    func plainButtonSingleLine() {
        let context = createTestContext()
        defer { cleanupEnvironment() }

        let button = Button("Test", style: .plain) {}
        let buffer = renderToBuffer(button, context: context)

        // Plain style: no border, just the label
        #expect(buffer.height == 1)
    }

    @Test("Focused button has focus indicator")
    func focusedButtonHasIndicator() {
        let context = createTestContext()
        defer { cleanupEnvironment() }

        let button = Button("Focus Me", focusID: "focused-button") {}
        let buffer = renderToBuffer(button, context: context)

        // First button is auto-focused, should have indicator
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("▸"))
    }

    @Test("Button default focused style is cyan")
    func buttonDefaultFocusedStyle() {
        let button = Button("Test") {}

        // Default focused style should have cyan color
        #expect(button.focusedStyle.foregroundColor == .cyan)
        #expect(button.focusedStyle.borderColor == .cyan)
        #expect(button.focusedStyle.isBold == true)
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
        defer { cleanupEnvironment() }

        let row = ButtonRow {
            Button("Cancel") {}
            Button("OK") {}
        }

        let buffer = renderToBuffer(row, context: context)

        #expect(!buffer.isEmpty)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Cancel"))
        #expect(allContent.contains("OK"))
    }

    @Test("ButtonRow with custom spacing")
    func buttonRowSpacing() {
        let context = createTestContext()
        defer { cleanupEnvironment() }

        let row = ButtonRow(spacing: 5) {
            Button("A", style: .plain) {}
            Button("B", style: .plain) {}
        }

        let buffer = renderToBuffer(row, context: context)

        #expect(!buffer.isEmpty)
        // Both buttons should be present
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("A"))
        #expect(allContent.contains("B"))
    }

    @Test("Empty ButtonRow returns empty buffer")
    func emptyButtonRow() {
        let row = ButtonRow {}
        let context = createTestContext()
        defer { cleanupEnvironment() }

        let buffer = renderToBuffer(row, context: context)

        #expect(buffer.isEmpty)
    }

    @Test("ButtonRow renders buttons horizontally")
    func buttonRowHorizontal() {
        let context = createTestContext()
        defer { cleanupEnvironment() }

        let row = ButtonRow {
            Button("First", style: .plain) {}
            Button("Second", style: .plain) {}
        }

        let buffer = renderToBuffer(row, context: context)

        // Should have same number of lines (horizontal layout)
        // Plain buttons are single line, so the row should be single line
        #expect(buffer.height == 1)
    }

    @Test("ButtonRow normalizes button heights")
    func buttonRowNormalizesHeights() {
        let context = createTestContext()
        defer { cleanupEnvironment() }

        let row = ButtonRow {
            Button("Border", style: .default) {}  // 3 lines with border
            Button("Plain", style: .plain) {}     // 1 line without border
        }

        let buffer = renderToBuffer(row, context: context)

        // Should use the maximum height (3 lines from bordered button)
        #expect(buffer.height == 3)
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
            [Button("B") {}, Button("C") {}]
        ]
        let result = ButtonRowBuilder.buildArray(groups)

        #expect(result.count == 3)
    }
}
