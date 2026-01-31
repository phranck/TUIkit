# Focus System

Navigate between interactive elements using the keyboard.

## Overview

TUIkit provides a focus system that lets users move between interactive views (buttons, menus, text fields) using Tab, Shift+Tab, or arrow keys. The system consists of three parts:

- **``FocusManager``** — Tracks which element is focused, handles navigation
- **``Focusable``** — Protocol that views adopt to receive focus
- **``FocusState``** — Lightweight state object that views use to query and request focus

## How Focus Works

Every frame, the ``FocusManager`` is cleared and interactive views re-register themselves during rendering. This means focus registrations are always in sync with the current view tree — removed views are automatically unregistered.

The focus order follows the rendering order: the first focusable view rendered is first in the Tab cycle.

## The Focusable Protocol

Views that want to receive focus conform to ``Focusable``:

```swift
protocol Focusable: AnyObject {
    var focusID: String { get }
    var canBeFocused: Bool { get }
    func onFocusReceived()
    func onFocusLost()
    func handleKeyEvent(_ event: KeyEvent) -> Bool
}
```

- **`focusID`** — Unique identifier for this focusable element
- **`canBeFocused`** — Whether focus can move to this element (default: `true`)
- **`onFocusReceived()`** — Called when this element gains focus (default: no-op)
- **`onFocusLost()`** — Called when this element loses focus (default: no-op)
- **`handleKeyEvent(_:)`** — Handle a key event while focused; return `true` if consumed

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

Built-in views like ``Button`` and ``Menu`` create their own `FocusState` internally — you only need it when building custom focusable views.

## Navigation Keys

The ``FocusManager`` responds to these keys during dispatch:

| Key | Action |
|-----|--------|
| Tab | Move focus to the next element |
| Shift+Tab | Move focus to the previous element |
| Arrow Down / Right | Move focus to the next element |
| Arrow Up / Left | Move focus to the previous element |

## Focus Indicator

The currently focused element is rendered with **bold** text styling. There is no arrow or marker — bold is the sole visual indicator.

## Focus in the Event Loop

Focus dispatch happens in Layer 2 of the key event pipeline (see <doc:AppLifecycle>):

1. A key event arrives from stdin
2. Layer 1 (status bar) gets first chance to handle it
3. Layer 2: ``KeyEventDispatcher`` dispatches to the focused view's `handleKeyEvent(_:)`
4. If not consumed, navigation keys (Tab, arrows) are handled by ``FocusManager``
5. Layer 3 (default bindings) handles quit, theme cycling, etc.
