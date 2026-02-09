//  TUIKit - Terminal UI Kit for Swift
//  TextFieldHandlerTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - TextFieldHandler Tests

@MainActor
@Suite("TextFieldHandler Tests")
struct TextFieldHandlerTests {

    // MARK: - Initialization

    @Test("Handler initializes with correct defaults")
    func initializationDefaults() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })

        let handler = TextFieldHandler(focusID: "test", text: binding)

        #expect(handler.focusID == "test")
        #expect(handler.canBeFocused == true)
        #expect(handler.cursorPosition == 5)  // End of "Hello"
    }

    @Test("Handler initializes with custom cursor position")
    func initializationWithCursorPosition() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })

        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 2)

        #expect(handler.cursorPosition == 2)
    }

    @Test("Handler initializes with empty text")
    func initializationEmptyText() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        let handler = TextFieldHandler(focusID: "test", text: binding)

        #expect(handler.cursorPosition == 0)
    }

    // MARK: - Character Insertion

    @Test("Insert character at end")
    func insertCharacterAtEnd() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        handler.insertCharacter("!")

        #expect(text == "Hello!")
        #expect(handler.cursorPosition == 6)
    }

    @Test("Insert character in middle")
    func insertCharacterInMiddle() {
        var text = "Hllo"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 1)

        handler.insertCharacter("e")

        #expect(text == "Hello")
        #expect(handler.cursorPosition == 2)
    }

    @Test("Insert character at start")
    func insertCharacterAtStart() {
        var text = "ello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 0)

        handler.insertCharacter("H")

        #expect(text == "Hello")
        #expect(handler.cursorPosition == 1)
    }

    @Test("Insert space character")
    func insertSpaceCharacter() {
        var text = "HelloWorld"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 5)

        handler.insertCharacter(" ")

        #expect(text == "Hello World")
        #expect(handler.cursorPosition == 6)
    }

    // MARK: - Delete Backward (Backspace)

    @Test("Delete backward removes character before cursor")
    func deleteBackward() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        handler.deleteBackward()

        #expect(text == "Hell")
        #expect(handler.cursorPosition == 4)
    }

    @Test("Delete backward in middle of text")
    func deleteBackwardMiddle() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 3)

        handler.deleteBackward()

        #expect(text == "Helo")
        #expect(handler.cursorPosition == 2)
    }

    @Test("Delete backward at start does nothing")
    func deleteBackwardAtStart() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 0)

        handler.deleteBackward()

        #expect(text == "Hello")
        #expect(handler.cursorPosition == 0)
    }

    // MARK: - Delete Forward (Delete Key)

    @Test("Delete forward removes character at cursor")
    func deleteForward() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 0)

        handler.deleteForward()

        #expect(text == "ello")
        #expect(handler.cursorPosition == 0)
    }

    @Test("Delete forward in middle of text")
    func deleteForwardMiddle() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 2)

        handler.deleteForward()

        #expect(text == "Helo")
        #expect(handler.cursorPosition == 2)
    }

    @Test("Delete forward at end does nothing")
    func deleteForwardAtEnd() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)  // Cursor at end

        handler.deleteForward()

        #expect(text == "Hello")
        #expect(handler.cursorPosition == 5)
    }

    // MARK: - Cursor Movement

    @Test("Move cursor left")
    func moveCursorLeft() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        handler.moveCursorLeft()

        #expect(handler.cursorPosition == 4)
    }

    @Test("Move cursor left at start stays at 0")
    func moveCursorLeftAtStart() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 0)

        handler.moveCursorLeft()

        #expect(handler.cursorPosition == 0)
    }

    @Test("Move cursor right")
    func moveCursorRight() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 2)

        handler.moveCursorRight()

        #expect(handler.cursorPosition == 3)
    }

    @Test("Move cursor right at end stays at end")
    func moveCursorRightAtEnd() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)  // Cursor at end

        handler.moveCursorRight()

        #expect(handler.cursorPosition == 5)
    }

    // MARK: - Key Event Handling

    @Test("Character key event inserts character")
    func handleCharacterKeyEvent() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("A")))

        #expect(handled == true)
        #expect(text == "A")
    }

    @Test("Backspace key event deletes backward")
    func handleBackspaceKeyEvent() {
        var text = "AB"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        let handled = handler.handleKeyEvent(KeyEvent(key: .backspace))

        #expect(handled == true)
        #expect(text == "A")
    }

    @Test("Delete key event deletes forward")
    func handleDeleteKeyEvent() {
        var text = "AB"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 0)

        let handled = handler.handleKeyEvent(KeyEvent(key: .delete))

        #expect(handled == true)
        #expect(text == "B")
    }

    @Test("Left arrow key event moves cursor left")
    func handleLeftArrowKeyEvent() {
        var text = "AB"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        let handled = handler.handleKeyEvent(KeyEvent(key: .left))

        #expect(handled == true)
        #expect(handler.cursorPosition == 1)
    }

    @Test("Right arrow key event moves cursor right")
    func handleRightArrowKeyEvent() {
        var text = "AB"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 0)

        let handled = handler.handleKeyEvent(KeyEvent(key: .right))

        #expect(handled == true)
        #expect(handler.cursorPosition == 1)
    }

    @Test("Home key event moves cursor to start")
    func handleHomeKeyEvent() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        let handled = handler.handleKeyEvent(KeyEvent(key: .home))

        #expect(handled == true)
        #expect(handler.cursorPosition == 0)
    }

    @Test("End key event moves cursor to end")
    func handleEndKeyEvent() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 0)

        let handled = handler.handleKeyEvent(KeyEvent(key: .end))

        #expect(handled == true)
        #expect(handler.cursorPosition == 5)
    }

    @Test("Enter key event triggers onSubmit")
    func handleEnterKeyEvent() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        var submitCalled = false
        handler.onSubmit = { submitCalled = true }

        let handled = handler.handleKeyEvent(KeyEvent(key: .enter))

        #expect(handled == true)
        #expect(submitCalled == true)
    }

    @Test("Unhandled key event returns false")
    func handleUnhandledKeyEvent() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        let handled = handler.handleKeyEvent(KeyEvent(key: .f1))

        #expect(handled == false)
    }

    // MARK: - Cursor Clamping

    @Test("Clamp cursor position when text shrinks")
    func clampCursorPosition() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        // Simulate external text change
        text = "Hi"
        handler.text = binding
        handler.clampCursorPosition()

        #expect(handler.cursorPosition == 2)  // Clamped to "Hi".count
    }

    // MARK: - Autocapitalization

    @Test("Autocapitalization never does not transform")
    func autocapitalizationNever() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)
        handler.autocapitalization = .never

        handler.insertCharacter("a")
        handler.insertCharacter("b")

        #expect(text == "ab")
    }

    @Test("Autocapitalization characters uppercases all")
    func autocapitalizationCharacters() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)
        handler.autocapitalization = .characters

        handler.insertCharacter("a")
        handler.insertCharacter("b")

        #expect(text == "AB")
    }

    @Test("Autocapitalization words capitalizes first letter of each word")
    func autocapitalizationWords() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)
        handler.autocapitalization = .words

        handler.insertCharacter("h")
        handler.insertCharacter("e")
        handler.insertCharacter("l")
        handler.insertCharacter("l")
        handler.insertCharacter("o")
        handler.insertCharacter(" ")
        handler.insertCharacter("w")
        handler.insertCharacter("o")
        handler.insertCharacter("r")
        handler.insertCharacter("l")
        handler.insertCharacter("d")

        #expect(text == "Hello World")
    }

    @Test("Autocapitalization sentences capitalizes after sentence end")
    func autocapitalizationSentences() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)
        handler.autocapitalization = .sentences

        // "hi. hello"
        handler.insertCharacter("h")
        handler.insertCharacter("i")
        handler.insertCharacter(".")
        handler.insertCharacter(" ")
        handler.insertCharacter("h")
        handler.insertCharacter("e")
        handler.insertCharacter("l")
        handler.insertCharacter("l")
        handler.insertCharacter("o")

        #expect(text == "Hi. Hello")
    }
}
