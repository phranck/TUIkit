# TextField Selection Support

## Completed

**Date:** 2026-02-09

## Preface

This plan adds text selection to TextField and SecureField. Users can select text using Shift+Arrow keys, with Shift+Left/Right extending character-by-character and Shift+Up/Down selecting to start/end (since single-line fields have no vertical navigation). Selected text is visually highlighted and can be deleted with Backspace/Delete or replaced by typing. This requires extending the CSI parser to recognize modifier codes in escape sequences and adding selection state to TextFieldHandler.

## Checklist

### Phase 1: CSI Parser Modifier Support
- [x] Parse modifier codes in CSI sequences (`;2` = Shift, `;5` = Ctrl)
- [x] Support `ESC [1;2A` format (Shift+Arrow)
- [x] Support `ESC [1;2H` / `ESC [1;2F` (Shift+Home/End)
- [x] Add tests for modifier parsing

### Phase 2: Selection State in TextFieldHandler
- [x] Add `selectionAnchor: Int?` property (nil = no selection)
- [x] Computed property `selectionRange` returns Range<Int>?
- [x] `clearSelection()` helper method
- [x] Update `clampCursorPosition()` to also clamp anchor

### Phase 3: Selection Keyboard Handling
- [x] Shift+Left: extend selection left by 1 character
- [x] Shift+Right: extend selection right by 1 character
- [x] Shift+Up: extend selection to text start
- [x] Shift+Down: extend selection to text end
- [x] Shift+Home: extend selection to text start (alternative)
- [x] Shift+End: extend selection to text end (alternative)
- [x] Any arrow without Shift: clear selection, move cursor

### Phase 4: Selection Rendering
- [x] Render selected text with highlight background
- [x] Selection works with horizontal scrolling
- [x] SecureField shows selected bullets with highlight

### Phase 5: Selection Editing
- [x] Backspace with selection: delete selected text
- [x] Delete with selection: delete selected text
- [x] Typing with selection: replace selected text
- [x] Paste: N/A (clipboard not yet implemented)

### Phase 6: Testing & Polish
- [x] TextFieldHandler selection tests (27 new tests)
- [x] KeyEvent modifier tests (14 new tests)
- [x] Selection rendering integrated in TextField/SecureField

## Context / Problem

TextField and SecureField currently support only cursor movement without selection. Users cannot:
- Select a portion of text to delete it
- Select text to replace it by typing
- Visually see what text will be affected by delete operations

This is a standard text editing feature that users expect from any text input.

## Specification / Goal

### Success Criteria

1. **Shift+Arrow selection**: Extend selection in the direction pressed
2. **Visual feedback**: Selected text has distinct background color
3. **Delete selection**: Backspace/Delete removes entire selection
4. **Replace selection**: Typing replaces selected text
5. **Works in both**: TextField and SecureField (masked bullets)
6. **All tests pass**

### Terminal Considerations

- Modifier keys in escape sequences vary by terminal
- Most modern terminals support xterm-style modifier encoding
- Format: `ESC [ 1 ; <modifier> <key>` where modifier 2 = Shift

## Design

### CSI Modifier Codes

Standard xterm modifier encoding in CSI sequences:

| Modifier | Code | Example |
|----------|------|---------|
| Shift | 2 | `ESC [1;2A` = Shift+Up |
| Alt | 3 | `ESC [1;3A` = Alt+Up |
| Shift+Alt | 4 | `ESC [1;4A` = Shift+Alt+Up |
| Ctrl | 5 | `ESC [1;5A` = Ctrl+Up |
| Shift+Ctrl | 6 | `ESC [1;6A` = Shift+Ctrl+Up |

Format: `ESC [ <param> ; <modifier> <final>`

For arrows: `ESC [1;2A` (Up), `ESC [1;2B` (Down), `ESC [1;2C` (Right), `ESC [1;2D` (Left)
For Home/End: `ESC [1;2H` (Home), `ESC [1;2F` (End)

### Selection State

```swift
final class TextFieldHandler: Focusable {
    var cursorPosition: Int
    var selectionAnchor: Int?  // nil = no selection
    
    /// Returns the selection range, or nil if no selection.
    var selectionRange: Range<Int>? {
        guard let anchor = selectionAnchor else { return nil }
        let start = min(anchor, cursorPosition)
        let end = max(anchor, cursorPosition)
        return start..<end
    }
    
    /// Clears the current selection.
    func clearSelection() {
        selectionAnchor = nil
    }
}
```

### Selection Behavior

**Starting selection:**
- Shift+Arrow when no selection: set anchor at current position, then move cursor

**Extending selection:**
- Shift+Arrow when selection exists: move cursor (anchor stays)

**Clearing selection:**
- Any arrow without Shift: clear selection, move cursor
- Escape: clear selection (cursor stays)
- Any character input: clear selection (after replacing if selected)

### Rendering with Selection

```
No selection:      ❙ Hello█World      ❙
With selection:    ❙ Hel[lo Wo]█rld   ❙  (lo Wo highlighted)
Full selection:    ❙ [Hello World]█   ❙  (all highlighted)
```

Selection highlight: Use `palette.accent` as background with contrasting foreground.

### Editing with Selection

```swift
func insertCharacter(_ char: Character) {
    if let range = selectionRange {
        // Delete selected text first
        deleteRange(range)
        clearSelection()
    }
    // Insert character at cursor
    // ...existing code...
}

func deleteBackward() {
    if let range = selectionRange {
        deleteRange(range)
        clearSelection()
        return
    }
    // ...existing single-character delete...
}
```

## Implementation Plan

### Phase 1: CSI Parser (45 min)

1. Modify `parseCSISequence` in `KeyEvent.swift`
2. Extract modifier code from `;n` parameter
3. Set `shift`, `ctrl`, `alt` flags based on modifier
4. Add unit tests for modified sequences

### Phase 2: Selection State (30 min)

1. Add `selectionAnchor` to `TextFieldHandler`
2. Add `selectionRange` computed property
3. Add `clearSelection()` method
4. Update `clampCursorPosition()` to handle anchor

### Phase 3: Selection Keyboard (45 min)

1. Handle Shift+Left/Right in `handleKeyEvent`
2. Handle Shift+Up/Down for start/end
3. Handle Shift+Home/End
4. Clear selection on non-shift navigation

### Phase 4: Selection Rendering (60 min)

1. Modify `buildTextWithCursor` in `_TextFieldCore`
2. Split text into: before-selection, selection, after-selection
3. Apply highlight background to selection segment
4. Handle scrolling with selection
5. Apply same changes to `_SecureFieldCore`

### Phase 5: Selection Editing (30 min)

1. Modify `insertCharacter` to replace selection
2. Modify `deleteBackward` to delete selection
3. Modify `deleteForward` to delete selection

### Phase 6: Testing (45 min)

1. CSI parser modifier tests
2. TextFieldHandler selection state tests
3. TextField selection rendering tests
4. SecureField selection rendering tests

## Files

### Modified Files
- `Sources/TUIkit/Core/KeyEvent.swift` - CSI modifier parsing
- `Sources/TUIkit/Focus/TextFieldHandler.swift` - Selection state and editing
- `Sources/TUIkit/Views/TextField.swift` - Selection rendering
- `Sources/TUIkit/Views/SecureField.swift` - Selection rendering

### New/Modified Test Files
- `Tests/TUIkitTests/KeyEventTests.swift` - Modifier parsing tests
- `Tests/TUIkitTests/TextFieldHandlerTests.swift` - Selection tests
- `Tests/TUIkitTests/TextFieldTests.swift` - Selection rendering tests
- `Tests/TUIkitTests/SecureFieldTests.swift` - Selection rendering tests

## Open Questions

1. **Select All (Ctrl+A)?** - Should we support this? Would need Ctrl modifier parsing.
2. **Word selection (Ctrl+Shift+Arrow)?** - Jump by word with selection? More complex.
3. **Double-click to select word?** - Not applicable (no mouse support).
4. **Selection color:** Use `palette.accent` background or introduce new `palette.selection`?

## Dependencies

- Existing TextFieldHandler architecture
- Existing KeyEvent parsing infrastructure
- Palette system for selection colors
