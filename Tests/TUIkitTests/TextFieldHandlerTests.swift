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

    // MARK: - Selection State

    @Test("No selection by default")
    func noSelectionByDefault() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        #expect(handler.selectionAnchor == nil)
        #expect(handler.hasSelection == false)
        #expect(handler.selectionRange == nil)
    }

    @Test("Selection range normalizes anchor and cursor")
    func selectionRangeNormalized() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 4)

        // Set anchor at position 1 (selecting "ell" from left to right)
        handler.selectionAnchor = 1
        #expect(handler.selectionRange == 1..<4)

        // Swap: anchor at 4, cursor at 1 (selecting "ell" from right to left)
        handler.selectionAnchor = 4
        handler.cursorPosition = 1
        #expect(handler.selectionRange == 1..<4)  // Still normalized
    }

    @Test("Empty selection when anchor equals cursor")
    func emptySelectionWhenAnchorEqualsCursor() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 2)

        handler.selectionAnchor = 2
        #expect(handler.hasSelection == false)
        #expect(handler.selectionRange == nil)
    }

    @Test("Clear selection removes anchor")
    func clearSelectionRemovesAnchor() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 4)
        handler.selectionAnchor = 1

        handler.clearSelection()

        #expect(handler.selectionAnchor == nil)
        #expect(handler.hasSelection == false)
    }

    @Test("Start selection sets anchor at current cursor")
    func startSelectionSetsAnchor() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 2)

        handler.startOrExtendSelection()

        #expect(handler.selectionAnchor == 2)
    }

    @Test("Extend selection keeps existing anchor")
    func extendSelectionKeepsAnchor() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 2)
        handler.selectionAnchor = 1

        handler.startOrExtendSelection()

        #expect(handler.selectionAnchor == 1)  // Unchanged
    }

    @Test("Delete range removes selected text")
    func deleteRangeRemovesSelectedText() {
        var text = "Hello World"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        handler.deleteRange(2..<8)  // Remove "llo Wo"

        #expect(text == "Herld")
        #expect(handler.cursorPosition == 2)
    }

    @Test("Clamp also clamps selection anchor")
    func clampClampsSelectionAnchor() {
        var text = "Hello World"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 10)
        handler.selectionAnchor = 8

        // Simulate external text change
        text = "Hi"
        handler.text = binding
        handler.clampCursorPosition()

        #expect(handler.cursorPosition == 2)
        #expect(handler.selectionAnchor == 2)
    }

    // MARK: - Selection Keyboard Handling

    @Test("Shift+Left extends selection left")
    func shiftLeftExtendsSelectionLeft() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 3)

        let handled = handler.handleKeyEvent(KeyEvent(key: .left, shift: true))

        #expect(handled == true)
        #expect(handler.selectionAnchor == 3)
        #expect(handler.cursorPosition == 2)
        #expect(handler.selectionRange == 2..<3)
    }

    @Test("Shift+Right extends selection right")
    func shiftRightExtendsSelectionRight() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 2)

        let handled = handler.handleKeyEvent(KeyEvent(key: .right, shift: true))

        #expect(handled == true)
        #expect(handler.selectionAnchor == 2)
        #expect(handler.cursorPosition == 3)
        #expect(handler.selectionRange == 2..<3)
    }

    @Test("Shift+Up selects to start")
    func shiftUpSelectsToStart() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 3)

        let handled = handler.handleKeyEvent(KeyEvent(key: .up, shift: true))

        #expect(handled == true)
        #expect(handler.selectionAnchor == 3)
        #expect(handler.cursorPosition == 0)
        #expect(handler.selectionRange == 0..<3)
    }

    @Test("Shift+Down selects to end")
    func shiftDownSelectsToEnd() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 2)

        let handled = handler.handleKeyEvent(KeyEvent(key: .down, shift: true))

        #expect(handled == true)
        #expect(handler.selectionAnchor == 2)
        #expect(handler.cursorPosition == 5)
        #expect(handler.selectionRange == 2..<5)
    }

    @Test("Shift+Home selects to start")
    func shiftHomeSelectsToStart() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 4)

        let handled = handler.handleKeyEvent(KeyEvent(key: .home, shift: true))

        #expect(handled == true)
        #expect(handler.selectionAnchor == 4)
        #expect(handler.cursorPosition == 0)
        #expect(handler.selectionRange == 0..<4)
    }

    @Test("Shift+End selects to end")
    func shiftEndSelectsToEnd() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 1)

        let handled = handler.handleKeyEvent(KeyEvent(key: .end, shift: true))

        #expect(handled == true)
        #expect(handler.selectionAnchor == 1)
        #expect(handler.cursorPosition == 5)
        #expect(handler.selectionRange == 1..<5)
    }

    @Test("Arrow without shift clears selection")
    func arrowWithoutShiftClearsSelection() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 3)
        handler.selectionAnchor = 1

        _ = handler.handleKeyEvent(KeyEvent(key: .right))

        #expect(handler.selectionAnchor == nil)
        #expect(handler.hasSelection == false)
        #expect(handler.cursorPosition == 4)
    }

    @Test("Home without shift clears selection")
    func homeWithoutShiftClearsSelection() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 3)
        handler.selectionAnchor = 1

        _ = handler.handleKeyEvent(KeyEvent(key: .home))

        #expect(handler.selectionAnchor == nil)
        #expect(handler.cursorPosition == 0)
    }

    @Test("End without shift clears selection")
    func endWithoutShiftClearsSelection() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 2)
        handler.selectionAnchor = 1

        _ = handler.handleKeyEvent(KeyEvent(key: .end))

        #expect(handler.selectionAnchor == nil)
        #expect(handler.cursorPosition == 5)
    }

    @Test("Up without shift clears selection and moves to start")
    func upWithoutShiftClearsSelectionAndMovesToStart() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 3)
        handler.selectionAnchor = 1

        _ = handler.handleKeyEvent(KeyEvent(key: .up))

        #expect(handler.selectionAnchor == nil)
        #expect(handler.cursorPosition == 0)
    }

    @Test("Down without shift clears selection and moves to end")
    func downWithoutShiftClearsSelectionAndMovesToEnd() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 2)
        handler.selectionAnchor = 1

        _ = handler.handleKeyEvent(KeyEvent(key: .down))

        #expect(handler.selectionAnchor == nil)
        #expect(handler.cursorPosition == 5)
    }

    @Test("Multiple Shift+Left extends selection progressively")
    func multipleShiftLeftExtendsProgressively() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 4)

        _ = handler.handleKeyEvent(KeyEvent(key: .left, shift: true))
        _ = handler.handleKeyEvent(KeyEvent(key: .left, shift: true))
        _ = handler.handleKeyEvent(KeyEvent(key: .left, shift: true))

        #expect(handler.selectionAnchor == 4)
        #expect(handler.cursorPosition == 1)
        #expect(handler.selectionRange == 1..<4)
    }

    @Test("Shift+Left at start does not move further")
    func shiftLeftAtStartDoesNotMoveFurther() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 0)

        _ = handler.handleKeyEvent(KeyEvent(key: .left, shift: true))

        #expect(handler.selectionAnchor == 0)
        #expect(handler.cursorPosition == 0)
        #expect(handler.hasSelection == false)  // Empty selection
    }

    @Test("Shift+Right at end does not move further")
    func shiftRightAtEndDoesNotMoveFurther() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)  // At end

        _ = handler.handleKeyEvent(KeyEvent(key: .right, shift: true))

        #expect(handler.selectionAnchor == 5)
        #expect(handler.cursorPosition == 5)
        #expect(handler.hasSelection == false)  // Empty selection
    }

    // MARK: - Selection Editing

    @Test("Backspace with selection deletes selected text")
    func backspaceWithSelectionDeletesSelectedText() {
        var text = "Hello World"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 8)
        handler.selectionAnchor = 2  // Select "llo Wo"

        _ = handler.handleKeyEvent(KeyEvent(key: .backspace))

        #expect(text == "Herld")
        #expect(handler.cursorPosition == 2)
        #expect(handler.hasSelection == false)
    }

    @Test("Delete with selection deletes selected text")
    func deleteWithSelectionDeletesSelectedText() {
        var text = "Hello World"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 5)
        handler.selectionAnchor = 0  // Select "Hello"

        _ = handler.handleKeyEvent(KeyEvent(key: .delete))

        #expect(text == " World")
        #expect(handler.cursorPosition == 0)
        #expect(handler.hasSelection == false)
    }

    @Test("Typing with selection replaces selected text")
    func typingWithSelectionReplacesSelectedText() {
        var text = "Hello World"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 5)
        handler.selectionAnchor = 0  // Select "Hello"

        _ = handler.handleKeyEvent(KeyEvent(key: .character("X")))

        #expect(text == "X World")
        #expect(handler.cursorPosition == 1)
        #expect(handler.hasSelection == false)
    }

    @Test("Typing multiple characters after selection replacement")
    func typingMultipleCharactersAfterSelectionReplacement() {
        var text = "Hello World"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 5)
        handler.selectionAnchor = 0  // Select "Hello"

        _ = handler.handleKeyEvent(KeyEvent(key: .character("A")))
        _ = handler.handleKeyEvent(KeyEvent(key: .character("B")))
        _ = handler.handleKeyEvent(KeyEvent(key: .character("C")))

        #expect(text == "ABC World")
        #expect(handler.cursorPosition == 3)
    }

    @Test("Select all and delete clears text")
    func selectAllAndDeleteClearsText() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 5)
        handler.selectionAnchor = 0  // Select all

        _ = handler.handleKeyEvent(KeyEvent(key: .backspace))

        #expect(text == "")
        #expect(handler.cursorPosition == 0)
    }

    @Test("Select all and type replaces all text")
    func selectAllAndTypeReplacesAllText() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 5)
        handler.selectionAnchor = 0  // Select all

        _ = handler.handleKeyEvent(KeyEvent(key: .character("X")))

        #expect(text == "X")
        #expect(handler.cursorPosition == 1)
    }

}
