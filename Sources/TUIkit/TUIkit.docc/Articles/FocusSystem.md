# Focus System

Navigate between interactive elements using the keyboard.

## Overview

TUIkit provides a focus system that lets users move between interactive views (buttons, menus, text fields) using Tab, Shift+Tab, or arrow keys. The system consists of three parts:

- **`FocusManager`**: Tracks which element is focused, handles navigation
- **``Focusable``**: Protocol that views adopt to receive focus
- **``FocusState``**: Lightweight state object that views use to query and request focus

## How Focus Works

Every frame, the `FocusManager` is cleared and interactive views re-register themselves during rendering. This means focus registrations are always in sync with the current view tree: removed views are automatically unregistered.

The focus order follows the rendering order: the first focusable view rendered is first in the Tab cycle.

## The Focusable Protocol

Views that want to receive focus conform to ``Focusable``:

```swift
public protocol Focusable: AnyObject {
    var focusID: String { get }
    var canBeFocused: Bool { get }
    func onFocusReceived()
    func onFocusLost()
    func handleKeyEvent(_ event: KeyEvent) -> Bool
}
```

- **`focusID`**: Unique identifier for this focusable element
- **`canBeFocused`**: Whether focus can move to this element (default: `true`)
- **`onFocusReceived()`**: Called when this element gains focus (default: no-op)
- **`onFocusLost()`**: Called when this element loses focus (default: no-op)
- **`handleKeyEvent(_:)`**: Handle a key event while focused; return `true` if consumed

A default extension provides sensible defaults for `canBeFocused` (`true`), `onFocusReceived()`, and `onFocusLost()` (both no-ops). Only `focusID` and `handleKeyEvent(_:)` must be implemented.

## Using FocusState

``FocusState`` is the user-facing API for checking and requesting focus inside a view:

```swift
let focusState = FocusState(id: "my-button", focusManager: context.environment.focusManager)

// Check if this element is currently focused
if focusState.isFocused {
    // render with focus indicator
}

// Programmatically request focus
focusState.requestFocus()
```

Built-in views like ``Button`` and ``Menu`` create their own `FocusState` internally: you only need it when building custom focusable views.

## Navigation Keys

The `FocusManager` responds to these keys during dispatch:

| Key | Action |
|-----|--------|
| Tab | Move focus to the next element |
| Shift+Tab | Move focus to the previous element |
| Arrow Down / Right | Move focus to the next element |
| Arrow Up / Left | Move focus to the previous element |

## FocusRegistration Helper

Built-in interactive views use the internal `FocusRegistration` helper to avoid boilerplate. It handles three tasks in one call:

1. **Persist a focus ID** via `StateStorage` so it remains stable across renders
2. **Register** the handler with the `FocusManager`
3. **Query** whether this view currently has focus

Custom views that implement ``Focusable`` typically do not need `FocusRegistration` directly. It is used by the framework's `_*Core` views (e.g. `_ButtonCore`, `_ListCore`).

## Focus Indicator

The visual indicator depends on the view type. Buttons and similar controls use a **highlight background bar** for the focused item. Text fields use **pulsing vertical bars** (caps) around the input area. Lists and tables use a **highlight background** for the focused row, with a **pulsing accent background** when the row is both focused and selected.

## Focus in the Event Loop

Focus dispatch happens in Layer 2 of the key event pipeline (see <doc:AppLifecycle>):

1. A key event arrives from stdin
2. Layer 1 (status bar) gets first chance to handle it
3. Layer 2: `KeyEventDispatcher` dispatches to the focused view's `handleKeyEvent(_:)`
4. If not consumed, navigation keys (Tab, arrows) are handled by `FocusManager`
5. Layer 3 (default bindings) handles quit, theme cycling, etc.
