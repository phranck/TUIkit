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
/// - Copy/Cut/Paste via system clipboard
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
/// | Ctrl+A | Select all text |
/// | Ctrl+C | Copy selection to clipboard |
/// | Ctrl+X | Cut selection to clipboard |
/// | Ctrl+V | Paste from clipboard |
/// | Ctrl+Z | Undo last change |
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

    /// The text content type used for input character filtering.
    ///
    /// When set, both typed characters and pasted text are filtered against
    /// the allowed character set of the content type. Synced from the
    /// environment during each render pass.
    var textContentType: TextContentType?

    /// Undo history stack storing previous text states and cursor positions.
    private var undoStack: [(text: String, cursor: Int)] = []

    /// Maximum number of undo states to keep.
    private let maxUndoStates = 50

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
    /// Pushes the current state to the undo stack before deleting.
    ///
    /// - Parameter range: The range of characters to delete.
    func deleteRange(_ range: Range<Int>) {
        pushUndoState()
        deleteRangeWithoutUndo(range)
    }

    /// Deletes the text in the given range without pushing to undo stack.
    ///
    /// Used internally when undo state has already been pushed.
    ///
    /// - Parameter range: The range of characters to delete.
    func deleteRangeWithoutUndo(_ range: Range<Int>) {
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
        case .space:
            insertCharacter(" ")
            return true

        case .character(let char):
            return handleCharacter(char, ctrl: event.ctrl)

        case .backspace:
            deleteBackward()
            return true

        case .delete:
            deleteForward()
            return true

        case .left, .right, .up, .down, .home, .end:
            return handleNavigation(event.key, extendingSelection: event.shift)

        case .enter:
            onSubmit?()
            return true

        case .paste(let text):
            insertText(text)
            return true

        default:
            return false
        }
    }

    /// Handles printable characters and Ctrl-based editing shortcuts.
    private func handleCharacter(_ char: Character, ctrl: Bool) -> Bool {
        if ctrl {
            switch char {
            case "a", "A": selectAll()
            case "c", "C": copySelection()
            case "x", "X": cutSelection()
            case "v", "V": paste()
            case "z", "Z": undo()
            default: return false
            }
            return true
        }

        guard char.isLetter || char.isNumber || char.isPunctuation ||
              char.isSymbol || char.isWhitespace else {
            return false
        }
        insertCharacter(char)
        return true
    }

    /// Handles cursor navigation with optional selection extension.
    private func handleNavigation(_ key: Key, extendingSelection: Bool) -> Bool {
        switch key {
        case .left:
            if extendingSelection {
                extendSelectionLeft()
            } else {
                moveLeftClearingSelection()
            }
        case .right:
            if extendingSelection {
                extendSelectionRight()
            } else {
                moveRightClearingSelection()
            }
        case .up, .home:
            if extendingSelection {
                extendSelectionToStart()
            } else {
                moveToStartClearingSelection()
            }
        case .down, .end:
            if extendingSelection {
                extendSelectionToEnd()
            } else {
                moveToEndClearingSelection()
            }
        default:
            return false
        }
        return true
    }

    private func moveLeftClearingSelection() {
        clearSelection()
        moveCursorLeft()
    }

    private func moveRightClearingSelection() {
        clearSelection()
        moveCursorRight()
    }

    private func moveToStartClearingSelection() {
        clearSelection()
        cursorPosition = 0
    }

    private func moveToEndClearingSelection() {
        clearSelection()
        cursorPosition = text.wrappedValue.count
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
        guard textContentType?.isAllowed(char) ?? true else { return }

        pushUndoState()

        // Replace selection if present
        if let range = selectionRange {
            deleteRangeWithoutUndo(range)
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
            pushUndoState()
            deleteRangeWithoutUndo(range)
            clearSelection()
            return
        }

        guard cursorPosition > 0 else { return }
        pushUndoState()
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
            pushUndoState()
            deleteRangeWithoutUndo(range)
            clearSelection()
            return
        }

        var current = text.wrappedValue
        guard cursorPosition < current.count else { return }
        pushUndoState()
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

// MARK: - Undo

extension TextFieldHandler {
    /// Pushes the current state onto the undo stack.
    func pushUndoState() {
        let state = (text: text.wrappedValue, cursor: cursorPosition)

        // Avoid duplicate states
        if let last = undoStack.last, last.text == state.text {
            return
        }

        undoStack.append(state)

        // Limit stack size
        if undoStack.count > maxUndoStates {
            undoStack.removeFirst()
        }
    }

    /// Restores the previous text state from the undo stack.
    func undo() {
        guard let previous = undoStack.popLast() else { return }
        text.wrappedValue = previous.text
        cursorPosition = min(previous.cursor, previous.text.count)
        clearSelection()
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
