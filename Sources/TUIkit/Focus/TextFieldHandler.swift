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
/// - Text selection with Shift+Arrow keys
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
/// | Any printable | Insert character at cursor (replaces selection) |
/// | Backspace | Delete selection or character before cursor |
/// | Delete | Delete selection or character at cursor |
/// | Left | Move cursor left (clears selection) |
/// | Right | Move cursor right (clears selection) |
/// | Home | Move cursor to start (clears selection) |
/// | End | Move cursor to end (clears selection) |
/// | Shift+Left | Extend selection left |
/// | Shift+Right | Extend selection right |
/// | Shift+Up | Select to start of text |
/// | Shift+Down | Select to end of text |
/// | Shift+Home | Select to start of text |
/// | Shift+End | Select to end of text |
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

    /// The selection anchor position (where selection started).
    /// When nil, there is no active selection.
    /// When set, the selection spans from `selectionAnchor` to `cursorPosition`.
    var selectionAnchor: Int?

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
        self.selectionAnchor = nil
    }
}

// MARK: - Selection

extension TextFieldHandler {
    /// Returns the current selection range, or nil if no selection.
    ///
    /// The range is always normalized (start < end) regardless of
    /// whether the user selected left-to-right or right-to-left.
    var selectionRange: Range<Int>? {
        guard let anchor = selectionAnchor else { return nil }
        guard anchor != cursorPosition else { return nil }  // Empty selection
        let start = min(anchor, cursorPosition)
        let end = max(anchor, cursorPosition)
        return start..<end
    }

    /// Returns true if there is an active text selection.
    var hasSelection: Bool {
        selectionRange != nil
    }

    /// Clears the current selection without moving the cursor.
    func clearSelection() {
        selectionAnchor = nil
    }

    /// Starts or extends a selection from the current cursor position.
    ///
    /// If no selection exists, sets the anchor at the current cursor position.
    /// If a selection exists, the anchor stays where it is.
    func startOrExtendSelection() {
        if selectionAnchor == nil {
            selectionAnchor = cursorPosition
        }
    }

    /// Deletes the text in the given range and positions cursor at start.
    ///
    /// - Parameter range: The range of characters to delete.
    func deleteRange(_ range: Range<Int>) {
        var current = text.wrappedValue
        let startIndex = current.index(current.startIndex, offsetBy: range.lowerBound)
        let endIndex = current.index(current.startIndex, offsetBy: range.upperBound)
        current.removeSubrange(startIndex..<endIndex)
        text.wrappedValue = current
        cursorPosition = range.lowerBound
    }

    /// Extends selection one character to the left.
    func extendSelectionLeft() {
        startOrExtendSelection()
        if cursorPosition > 0 {
            cursorPosition -= 1
        }
    }

    /// Extends selection one character to the right.
    func extendSelectionRight() {
        startOrExtendSelection()
        if cursorPosition < text.wrappedValue.count {
            cursorPosition += 1
        }
    }

    /// Extends selection to the start of the text.
    func extendSelectionToStart() {
        startOrExtendSelection()
        cursorPosition = 0
    }

    /// Extends selection to the end of the text.
    func extendSelectionToEnd() {
        startOrExtendSelection()
        cursorPosition = text.wrappedValue.count
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
            if event.shift {
                extendSelectionLeft()
            } else {
                clearSelection()
                moveCursorLeft()
            }
            return true

        case .right:
            if event.shift {
                extendSelectionRight()
            } else {
                clearSelection()
                moveCursorRight()
            }
            return true

        case .up:
            if event.shift {
                extendSelectionToStart()
            } else {
                clearSelection()
                cursorPosition = 0
            }
            return true

        case .down:
            if event.shift {
                extendSelectionToEnd()
            } else {
                clearSelection()
                cursorPosition = text.wrappedValue.count
            }
            return true

        case .home:
            if event.shift {
                extendSelectionToStart()
            } else {
                clearSelection()
                cursorPosition = 0
            }
            return true

        case .end:
            if event.shift {
                extendSelectionToEnd()
            } else {
                clearSelection()
                cursorPosition = text.wrappedValue.count
            }
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
    /// If text is selected, the selection is replaced with the character.
    ///
    /// - Parameter char: The character to insert.
    func insertCharacter(_ char: Character) {
        // Replace selection if present
        if let range = selectionRange {
            deleteRange(range)
            clearSelection()
        }

        var current = text.wrappedValue
        let index = current.index(current.startIndex, offsetBy: min(cursorPosition, current.count))
        current.insert(char, at: index)
        text.wrappedValue = current
        cursorPosition += 1
    }

    /// Deletes the character before the cursor (backspace).
    ///
    /// If text is selected, the entire selection is deleted.
    func deleteBackward() {
        // Delete selection if present
        if let range = selectionRange {
            deleteRange(range)
            clearSelection()
            return
        }

        guard cursorPosition > 0 else { return }
        var current = text.wrappedValue
        let index = current.index(current.startIndex, offsetBy: cursorPosition - 1)
        current.remove(at: index)
        text.wrappedValue = current
        cursorPosition -= 1
    }

    /// Deletes the character at the cursor position (delete key).
    ///
    /// If text is selected, the entire selection is deleted.
    func deleteForward() {
        // Delete selection if present
        if let range = selectionRange {
            deleteRange(range)
            clearSelection()
            return
        }

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

    /// Ensures the cursor position and selection anchor are within valid bounds.
    func clampCursorPosition() {
        let maxPos = text.wrappedValue.count
        cursorPosition = max(0, min(cursorPosition, maxPos))
        if let anchor = selectionAnchor {
            selectionAnchor = max(0, min(anchor, maxPos))
        }
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
