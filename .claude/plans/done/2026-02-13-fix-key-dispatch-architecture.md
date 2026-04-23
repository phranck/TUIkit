# Fix Key Event Dispatch Architecture

## Preface

This plan fixes a fundamental design flaw in the key event dispatch system.
When a text-input element (TextField/SecureField) is focused, character keys are
intercepted by StatusBar shortcuts and default bindings before reaching the
focused text field. The fix introduces a "text-input priority" check at the top
of `InputHandler.handle()`, giving the focused text field first access to key
events. Only keys the text field does not consume fall through to other layers.
The change touches exactly two files with minimal code additions.

## Context / Problem

The `InputHandler.handle()` method dispatches key events through a 4-layer chain:

```
Layer 1: StatusBar items  (intercepts 'c', 'm', 'd', etc.)
Layer 2: onKeyPress       (intercepts '-', '=', etc.)
Layer 3: FocusManager     (TextField handles chars here, but never gets them)
Layer 4: Default bindings (intercepts 'q', 't', 'a')
```

Layers 1, 2, and 4 consume printable character keys before Layer 3 (FocusManager)
can deliver them to the focused TextField. The FocusManager already knows whether
a text-input element is focused (`currentFocused` returns a `TextFieldHandler`),
but `InputHandler` never checks this.

**Concrete bug:** On the ImagePage, typing `c`, `m`, `d` into the URL TextField
triggers StatusBar shortcuts. Typing `q` quits the app entirely.

## Specification / Goal

- When a TextField or SecureField is focused, ALL printable character input,
  backspace, delete, arrows, home, end, and enter MUST reach the text field.
- Escape, Tab, and unhandled Ctrl+ combos MUST still fall through to other layers.
- When NO text-input is focused, the dispatch order remains unchanged.
- No changes to existing public API.

## Design

Add a computed property `hasTextInputFocus` on `FocusManager` that returns `true`
when `currentFocused is TextFieldHandler`. This works for both TextField and
SecureField since SecureField internally uses `TextFieldHandler`.

Modify `InputHandler.handle()` to check this property first. If true, dispatch to
`focusManager.dispatchKeyEvent(event)` before any other layer. If the text field
consumes the event, return immediately. If not, continue through the remaining layers.
Skip Layer 3 later since it was already attempted.

## Implementation Plan

1. Add `hasTextInputFocus` computed property to FocusManager
2. Rewrite `InputHandler.handle()` with text-input priority check
3. Build and run all tests

## Checklist

- [ ] 1. Add `hasTextInputFocus` to `Sources/TUIkit/Focus/Focus.swift`
- [ ] 2. Rewrite `handle()` in `Sources/TUIkit/App/InputHandler.swift`
- [ ] 3. `swift build` succeeds
- [ ] 4. `swift test` passes (all 1064+ tests)

## Files

- `Sources/TUIkit/Focus/Focus.swift` - Add `hasTextInputFocus` property
- `Sources/TUIkit/App/InputHandler.swift` - Rewrite dispatch logic
