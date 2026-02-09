# TextField Component

## Preface

This plan implements TextField, an essential text input component for TUIKit. TextField provides an editable single-line text interface with cursor navigation, text editing, and SwiftUI-conformant API. Users can type, delete, and navigate within the field using standard keyboard controls. The component supports placeholder text (prompt), focus states with visual feedback, and the `.onSubmit()` modifier for form submission. This is a fundamental building block for forms, search fields, and any user text input.

## Context / Problem

TUIKit currently has no way for users to enter text. All existing controls (Button, Toggle, Menu, List) are selection-based, not input-based. TextField is essential for:

- Login/authentication forms (username, password)
- Search functionality
- Configuration dialogs
- Any application requiring user text input

### SwiftUI TextField API

From the official documentation, TextField has these key signatures:

```swift
// Basic string binding
init(_ titleKey: LocalizedStringKey, text: Binding<String>)
init(_ title: S, text: Binding<String>) where S: StringProtocol

// With prompt (placeholder)
init(_ titleKey: LocalizedStringKey, text: Binding<String>, prompt: Text?)
init(_ title: S, text: Binding<String>, prompt: Text?) where S: StringProtocol

// With ViewBuilder label
init(text: Binding<String>, prompt: Text?, @ViewBuilder label: () -> Label)
```

Key behaviors:
- Updates the bound value **continuously** as the user types
- `.onSubmit(of:_:)` modifier invokes action on Enter
- `.focused($focusState)` for focus management
- `.textFieldStyle(_:)` for styling (`.plain`, `.roundedBorder`, etc.)

## Specification / Goal

### Success Criteria

1. **SwiftUI API parity**: Match TextField signatures exactly
2. **Text editing**: Insert, delete (backspace/delete), cursor movement
3. **Cursor navigation**: Left/Right arrows, Home/End
4. **Focus integration**: Register with FocusManager, visual focus indicator
5. **Prompt/placeholder**: Show when text is empty and not focused
6. **Submit action**: `.onSubmit()` modifier triggers on Enter
7. **Disabled state**: Prevent editing when disabled
8. **All tests pass**

### Terminal-Specific Considerations

- No mouse support (keyboard only)
- Single-line only (no multi-line in v1)
- No clipboard/paste support in v1 (terminal limitation)
- Cursor rendered as block or underscore character

## Design

### Visual Rendering

```
Unfocused, empty:     [Enter username...]        (prompt in dim)
Unfocused, with text: [john.doe             ]    (text in normal)
Focused, empty:       [█                    ]    (cursor, brackets pulse)
Focused, with text:   [john.d█e             ]    (cursor in text, brackets pulse)
Disabled:             [john.doe             ]    (dim text and brackets)
```

### Architecture

Following the established TUIKit pattern (like Toggle, Button):

```swift
// Public View
public struct TextField: View {
    let title: String
    let text: Binding<String>
    let prompt: Text?
    let focusID: String
    let isDisabled: Bool
    
    public var body: some View {
        _TextFieldCore(...)
    }
}

// Internal Renderable
private struct _TextFieldCore: View, Renderable {
    var body: Never { fatalError() }
    
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Register TextFieldHandler with FocusManager
        // Render text with cursor position
    }
}
```

### TextFieldHandler (Focusable)

New handler class for text field focus and key handling:

```swift
final class TextFieldHandler: Focusable {
    let focusID: String
    var canBeFocused: Bool
    
    // Text state
    var text: Binding<String>
    var cursorPosition: Int  // Character index
    
    // Callbacks
    var onSubmit: (() -> Void)?
    
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        switch event.key {
        case .character(let char):
            insertCharacter(char)
            return true
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
```

### State Persistence

Use `StateStorage` to persist cursor position between renders:

```swift
struct TextFieldState {
    var cursorPosition: Int
}
```

### Modifier Support

```swift
// onSubmit modifier (already exists in TUIKit?)
TextField("Username", text: $username)
    .onSubmit {
        login()
    }

// textFieldStyle modifier
TextField("Search", text: $query)
    .textFieldStyle(.roundedBorder)
```

## Implementation Plan

### Phase 1: Core TextField

1. Create `TextFieldHandler` in `Sources/TUIkit/Focus/`
2. Create `TextField.swift` in `Sources/TUIkit/Views/`
3. Implement basic rendering (text + cursor)
4. Implement character input
5. Implement backspace/delete
6. Implement cursor movement (left/right/home/end)
7. Add focus indicator (pulsing brackets)

### Phase 2: SwiftUI API Parity

1. Add `init(_:text:)` - basic
2. Add `init(_:text:prompt:)` - with placeholder
3. Add `init(text:prompt:label:)` - ViewBuilder label
4. Implement prompt/placeholder rendering

### Phase 3: Modifiers & Polish

1. Implement `.onSubmit()` support
2. Implement `.textFieldStyle(_:)` modifier
3. Add `.disabled()` support
4. Add width constraint support

### Phase 4: Testing

1. Unit tests for TextFieldHandler
2. Rendering tests for TextField
3. Focus integration tests
4. Example app integration

## Checklist

### Phase 1: Core TextField
- [ ] Create TextFieldHandler class
- [ ] Create TextField struct with body: some View
- [ ] Implement _TextFieldCore with Renderable
- [ ] Render text content with cursor
- [ ] Handle character input
- [ ] Handle backspace/delete
- [ ] Handle cursor movement (left/right)
- [ ] Handle home/end keys
- [ ] Add focus indicator (pulsing brackets)
- [ ] State persistence for cursor position

### Phase 2: SwiftUI API Parity
- [ ] init(_:text:) - basic initializer
- [ ] init(_:text:prompt:) - with placeholder
- [ ] init(text:prompt:label:) - ViewBuilder label
- [ ] Render prompt when empty and unfocused

### Phase 3: Modifiers & Polish
- [ ] .onSubmit() modifier support
- [ ] .textFieldStyle(_:) modifier
- [ ] TextFieldStyle protocol
- [ ] PlainTextFieldStyle
- [ ] RoundedBorderTextFieldStyle (default for TUI)
- [ ] .disabled() support
- [ ] Width/frame support

### Phase 4: Testing
- [ ] TextFieldHandler key event tests
- [ ] TextField rendering tests
- [ ] Focus integration tests
- [ ] Prompt/placeholder tests
- [ ] Style tests
- [ ] Example app demo page

## Open Questions

1. **Cursor representation**: Block (`█`), underscore (`_`), or pipe (`|`)?
   - Recommendation: Block when focused, hidden when unfocused

2. **Max length**: Should TextField support a character limit?
   - Can add later as `.limit(_:)` modifier

3. **Secure field**: Should we implement SecureField (password) in this plan or separately?
   - Recommendation: Separate plan, but design TextField to support masking

4. **Selection**: Should we support text selection (shift+arrows)?
   - v1: No, keep simple. Add in future version.

## Files

### New Files
- `Sources/TUIkit/Focus/TextFieldHandler.swift`
- `Sources/TUIkit/Views/TextField.swift`
- `Sources/TUIkit/Modifiers/TextFieldStyleModifier.swift`
- `Tests/TUIkitTests/TextFieldTests.swift`
- `Tests/TUIkitTests/TextFieldHandlerTests.swift`

### Modified Files
- `Sources/TUIkitExample/Pages/` - Add TextField demo page

## Dependencies

- FocusManager (for focus registration)
- StateStorage (for cursor position persistence)
- ActionHandler pattern (reference implementation)
- Existing View/Renderable architecture
