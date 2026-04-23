# SecureField Component

## Preface

This plan implements SecureField, a password input component for TUIKit. SecureField displays user input as bullet characters (●) instead of plain text, providing privacy for sensitive information like passwords and PINs. It shares most functionality with TextField (cursor navigation, text editing, focus handling) but masks the displayed content. The SwiftUI API is matched exactly, with init signatures using String bindings and optional prompts.

## Completed

**Date:** 2026-02-09

SecureField implemented with 15 tests. Reuses TextFieldHandler for key input handling. Displays ● (U+25CF) bullets instead of text. Full keyboard navigation and editing support. Example app page with password validation demo.

## Checklist

### Phase 1: Core SecureField
- [x] Create SecureField.swift with `body: some View`
- [x] Create _SecureFieldCore with masked rendering
- [x] Reuse TextFieldHandler for key input handling
- [x] Display bullets (●) instead of actual characters
- [x] Maintain cursor position with masked display

### Phase 2: SwiftUI API Parity
- [x] init(_:text:) - basic initializer
- [x] init(_:text:prompt:) - with placeholder

### Phase 3: Modifiers & Polish
- [x] .onSubmit() modifier support
- [x] .disabled() support
- [x] Focus indicator (pulsing vertical bars)

### Phase 4: Testing & Demo
- [x] SecureField rendering tests (15 tests)
- [x] SecureField masking behavior tests
- [x] Example app demo page (SecureFieldPage.swift)

## Context / Problem

TUIKit has TextField for plain text input but no secure input for passwords. Login forms and authentication flows require a way to enter sensitive data without displaying it on screen. SecureField fills this gap.

### SwiftUI SecureField API

From SwiftUI documentation:

```swift
// Basic string binding
init(_ titleKey: LocalizedStringKey, text: Binding<String>)
init<S>(_ title: S, text: Binding<String>) where S : StringProtocol

// With prompt (placeholder)
init(_ titleKey: LocalizedStringKey, text: Binding<String>, prompt: Text?)
init<S>(_ title: S, text: Binding<String>, prompt: Text?) where S : StringProtocol

// ViewBuilder label - not needed for TUI (no icons/images in terminals)
```

Key differences from TextField:
- Always masks input (no way to reveal)
- Same keyboard handling (no special password shortcuts)
- Same focus behavior

## Design

### Visual Rendering

```
Unfocused, empty:     Enter password...       (prompt in dim)
Unfocused, with text: ●●●●●●●●                (bullets, no cursor)
Focused, empty:       ❙ █                   ❙ (cursor, bars pulse)
Focused, with text:   ❙ ●●●●█●●●            ❙ (bullets + cursor, bars pulse)
Disabled:             ●●●●●●●●                (dim bullets)
```

### Architecture

```swift
// Public View (simplified - no generic Label)
public struct SecureField: View {
    let title: String
    let text: Binding<String>
    let prompt: Text?
    let focusID: String
    let isDisabled: Bool
    let onSubmitAction: (() -> Void)?
    
    public var body: some View {
        _SecureFieldCore(...)
    }
}

// Internal Renderable
private struct _SecureFieldCore: View, Renderable {
    var body: Never { fatalError() }
    
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Renders bullets instead of characters
    }
}
```

### Masking Character

Uses bullet character `●` (U+25CF Black Circle) for consistency with other TUIKit indicators (Toggle, RadioButton, Spinner).

### Code Reuse

SecureField reuses `TextFieldHandler` for key input since editing logic is identical. Only rendering differs (bullets vs. plain text).

## Files

### New Files
- `Sources/TUIkit/Views/SecureField.swift`
- `Tests/TUIkitTests/SecureFieldTests.swift`
- `Sources/TUIkitExample/Pages/SecureFieldPage.swift`

### Modified Files
- `Sources/TUIkitExample/ContentView.swift` - Added SecureField page and shortcut
- `Sources/TUIkitExample/Pages/MainMenuPage.swift` - Added menu item

## Dependencies

- `TextFieldHandler` (reused for key handling)
- `FocusManager` (for focus registration)
- `StateStorage` (for cursor position persistence)
