//  TUIKit - Terminal UI Kit for Swift
//  TextFieldSelectionTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - TextFieldHandler Selection Tests

@MainActor
@Suite("TextField Selection Tests")
struct TextFieldSelectionTests {

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

        #expect(text.isEmpty)
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

    // MARK: - Select All (Ctrl+A)

    @Test("Ctrl+A selects all text")
    func ctrlASelectsAllText() {
        var text = "Hello World"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 3)

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("a"), ctrl: true))

        #expect(handled == true)
        #expect(handler.selectionAnchor == 0)
        #expect(handler.cursorPosition == 11)
        #expect(handler.selectionRange == 0..<11)
    }

    @Test("Ctrl+A on empty text does nothing")
    func ctrlAOnEmptyTextDoesNothing() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("a"), ctrl: true))

        #expect(handled == true)
        #expect(handler.hasSelection == false)
    }

    // MARK: - Undo (Ctrl+Z)

    @Test("Ctrl+Z undoes character insertion")
    func ctrlZUndoesCharacterInsertion() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        // Insert a character
        _ = handler.handleKeyEvent(KeyEvent(key: .character("!")))
        #expect(text == "Hello!")

        // Undo
        let handled = handler.handleKeyEvent(KeyEvent(key: .character("z"), ctrl: true))
        #expect(handled == true)
        #expect(text == "Hello")
    }

    @Test("Ctrl+Z undoes backspace")
    func ctrlZUndoesBackspace() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        // Delete last character
        _ = handler.handleKeyEvent(KeyEvent(key: .backspace))
        #expect(text == "Hell")

        // Undo
        _ = handler.handleKeyEvent(KeyEvent(key: .character("z"), ctrl: true))
        #expect(text == "Hello")
    }

    @Test("Ctrl+Z undoes selection deletion")
    func ctrlZUndoesSelectionDeletion() {
        var text = "Hello World"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 5)
        handler.selectionAnchor = 0  // Select "Hello"

        // Delete selection
        _ = handler.handleKeyEvent(KeyEvent(key: .backspace))
        #expect(text == " World")

        // Undo
        _ = handler.handleKeyEvent(KeyEvent(key: .character("z"), ctrl: true))
        #expect(text == "Hello World")
    }

    @Test("Multiple undos work correctly")
    func multipleUndosWorkCorrectly() {
        var text = "Hi"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        // Type "ABC"
        _ = handler.handleKeyEvent(KeyEvent(key: .character("A")))
        _ = handler.handleKeyEvent(KeyEvent(key: .character("B")))
        _ = handler.handleKeyEvent(KeyEvent(key: .character("C")))
        #expect(text == "HiABC")

        // Undo three times
        _ = handler.handleKeyEvent(KeyEvent(key: .character("z"), ctrl: true))
        #expect(text == "HiAB")
        _ = handler.handleKeyEvent(KeyEvent(key: .character("z"), ctrl: true))
        #expect(text == "HiA")
        _ = handler.handleKeyEvent(KeyEvent(key: .character("z"), ctrl: true))
        #expect(text == "Hi")
    }

    @Test("Undo on empty stack does nothing")
    func undoOnEmptyStackDoesNothing() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding)

        // Try to undo without any changes
        let handled = handler.handleKeyEvent(KeyEvent(key: .character("z"), ctrl: true))

        #expect(handled == true)
        #expect(text == "Hello")  // Unchanged
    }

    // MARK: - Copy/Cut/Paste Key Handling

    @Test("Ctrl+C is handled (copy)")
    func ctrlCIsHandled() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 3)
        handler.selectionAnchor = 0

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("c"), ctrl: true))

        #expect(handled == true)
        // Text should be unchanged (copy, not cut)
        #expect(text == "Hello")
        #expect(handler.hasSelection == true)  // Selection preserved
    }

    @Test("Ctrl+X is handled (cut)")
    func ctrlXIsHandled() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 3)
        handler.selectionAnchor = 0  // Select "Hel"

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("x"), ctrl: true))

        #expect(handled == true)
        #expect(text == "lo")  // "Hel" was cut
        #expect(handler.hasSelection == false)
    }

    @Test("Ctrl+V is handled (paste)")
    func ctrlVIsHandled() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 5)

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("v"), ctrl: true))

        #expect(handled == true)
        // Actual paste result depends on clipboard content
    }

    @Test("Ctrl+C without selection does nothing")
    func ctrlCWithoutSelectionDoesNothing() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 3)
        // No selection

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("c"), ctrl: true))

        #expect(handled == true)
        #expect(text == "Hello")  // Unchanged
    }

    @Test("Ctrl+X without selection does nothing")
    func ctrlXWithoutSelectionDoesNothing() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let handler = TextFieldHandler(focusID: "test", text: binding, cursorPosition: 3)
        // No selection

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("x"), ctrl: true))

        #expect(handled == true)
        #expect(text == "Hello")  // Unchanged
    }
}
