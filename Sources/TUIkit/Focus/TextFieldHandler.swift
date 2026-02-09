//  TUIKit - Terminal UI Kit for Swift
//  TextFieldHandler.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A focus handler for text field components.
///
/// `TextFieldHandler` manages text editing state and keyboard input for
/// `TextField`. It handles:
/// - Character insertion at cursor position
/// - Backspace/delete for removing characters
/// - Cursor navigation (left/right/home/end)
/// - Submit action on Enter
///
/// ## Usage
///
/// ```swift
/// // In TextField's renderToBuffer:
/// let handler = TextFieldHandler(
///     focusID: focusID,
///     text: textBinding,
///     canBeFocused: !isDisabled
/// )
/// handler.onSubmit = submitAction
/// focusManager.register(handler, inSection: sectionID)
/// ```
///
/// ## Keyboard Controls
///
/// | Key | Action |
/// |-----|--------|
/// | Any printable | Insert character at cursor |
/// | Backspace | Delete character before cursor |
/// | Delete | Delete character at cursor |
/// | Left | Move cursor left |
/// | Right | Move cursor right |
/// | Home | Move cursor to start |
/// | End | Move cursor to end |
/// | Enter | Trigger submit action |
final class TextFieldHandler: Focusable {
    /// The unique identifier for this focusable element.
    let focusID: String

    /// The binding to the text content.
    var text: Binding<String>

    /// Whether this element can currently receive focus.
    var canBeFocused: Bool

    /// The cursor position (character index where next input will be inserted).
    var cursorPosition: Int

    /// Callback triggered when the user presses Enter.
    var onSubmit: (() -> Void)?

    /// Creates a text field handler.
    ///
    /// - Parameters:
    ///   - focusID: The unique focus identifier.
    ///   - text: The binding to the text content.
    ///   - canBeFocused: Whether this element can receive focus. Defaults to `true`.
    ///   - cursorPosition: The initial cursor position. Defaults to end of text.
    init(
        focusID: String,
        text: Binding<String>,
        canBeFocused: Bool = true,
        cursorPosition: Int? = nil
    ) {
        self.focusID = focusID
        self.text = text
        self.canBeFocused = canBeFocused
        self.cursorPosition = cursorPosition ?? text.wrappedValue.count
    }
}

// MARK: - Key Event Handling

extension TextFieldHandler {
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        switch event.key {
        case .character(let char):
            // Ignore control characters except printable ones
            if char.isLetter || char.isNumber || char.isPunctuation ||
               char.isSymbol || char.isWhitespace || char == " " {
                insertCharacter(char)
                return true
            }
            return false

        case .backspace:
            deleteBackward()
            return true

        case .delete:
            deleteForward()
            return true

        case .left:
            moveCursorLeft()
            return true

        case .right:
            moveCursorRight()
            return true

        case .home:
            cursorPosition = 0
            return true

        case .end:
            cursorPosition = text.wrappedValue.count
            return true

        case .enter:
            onSubmit?()
            return true

        default:
            return false
        }
    }
}

// MARK: - Text Editing

extension TextFieldHandler {
    /// Inserts a character at the current cursor position.
    ///
    /// - Parameter char: The character to insert.
    func insertCharacter(_ char: Character) {
        var current = text.wrappedValue
        let index = current.index(current.startIndex, offsetBy: min(cursorPosition, current.count))
        current.insert(char, at: index)
        text.wrappedValue = current
        cursorPosition += 1
    }

    /// Deletes the character before the cursor (backspace).
    func deleteBackward() {
        guard cursorPosition > 0 else { return }
        var current = text.wrappedValue
        let index = current.index(current.startIndex, offsetBy: cursorPosition - 1)
        current.remove(at: index)
        text.wrappedValue = current
        cursorPosition -= 1
    }

    /// Deletes the character at the cursor position (delete key).
    func deleteForward() {
        var current = text.wrappedValue
        guard cursorPosition < current.count else { return }
        let index = current.index(current.startIndex, offsetBy: cursorPosition)
        current.remove(at: index)
        text.wrappedValue = current
    }
}

// MARK: - Cursor Navigation

extension TextFieldHandler {
    /// Moves the cursor one position to the left.
    func moveCursorLeft() {
        if cursorPosition > 0 {
            cursorPosition -= 1
        }
    }

    /// Moves the cursor one position to the right.
    func moveCursorRight() {
        if cursorPosition < text.wrappedValue.count {
            cursorPosition += 1
        }
    }

    /// Ensures the cursor position is within valid bounds.
    func clampCursorPosition() {
        cursorPosition = max(0, min(cursorPosition, text.wrappedValue.count))
    }
}

// MARK: - Focus Lifecycle

extension TextFieldHandler {
    func onFocusReceived() {
        // Ensure cursor is at a valid position
        clampCursorPosition()
    }

    func onFocusLost() {
        // Nothing special needed when losing focus
    }
}
