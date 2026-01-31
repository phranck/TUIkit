# Keyboard Shortcuts

How keyboard input flows through TUIkit — from raw terminal bytes to your view handlers.

## Overview

TUIkit uses a layered event dispatch system. When a key is pressed, it passes through up to three layers. The first layer that consumes the event wins — remaining layers are skipped.

```
Terminal raw bytes
      │
      ▼
  KeyEvent.parse()
      │
      ▼
 ┌─────────────────────────────┐
 │  Layer 1: Status Bar Items  │  Shortcuts with actions (e.g. "q" quit)
 └────────────┬────────────────┘
              │ not consumed
              ▼
 ┌─────────────────────────────┐
 │  Layer 2: View Handlers     │  .onKeyPress() modifiers (deepest view first)
 └────────────┬────────────────┘
              │ not consumed
              ▼
 ┌─────────────────────────────┐
 │  Layer 3: Default Bindings  │  q=quit, t=theme, a=appearance
 └─────────────────────────────┘
```

Additionally, `Ctrl+C` (SIGINT) is handled at the OS signal level **before** any of these layers — it always terminates the application.

## Available Keys

The ``Key`` enum defines all keys that TUIkit can recognize from terminal input:

### Character Keys

Any printable character is represented as `.character(Character)`:

```swift
.onKeyPress(Key.from("x")) {
    // handle "x" key
}
```

Uppercase detection: when a capital letter is typed, the resulting ``KeyEvent`` has `shift: true` set automatically.

### Special Keys

| Key | Description |
|-----|-------------|
| `.escape` | Escape key |
| `.enter` | Enter / Return |
| `.tab` | Tab |
| `.backspace` | Backspace / Delete backward |
| `.delete` | Forward delete |

### Arrow Keys

| Key | Description |
|-----|-------------|
| `.up` | Arrow up |
| `.down` | Arrow down |
| `.left` | Arrow left |
| `.right` | Arrow right |

### Navigation Keys

| Key | Description |
|-----|-------------|
| `.home` | Home |
| `.end` | End |
| `.pageUp` | Page Up |
| `.pageDown` | Page Down |

## Key Events and Modifiers

A ``KeyEvent`` combines a ``Key`` with modifier flags:

```swift
public struct KeyEvent {
    public let key: Key
    public let ctrl: Bool     // Ctrl modifier
    public let alt: Bool      // Alt / Option modifier
    public let shift: Bool    // Shift modifier
}
```

The terminal encodes modifiers differently from GUI frameworks:

- **Ctrl+letter** — Detected from ASCII control codes (0x01–0x1A). For example, `Ctrl+C` produces byte `0x03`.
- **Alt+key** — Detected from ESC prefix sequences (`ESC` followed by the key byte).
- **Shift** — Only auto-detected for uppercase letters. The terminal does not send distinct shift codes for most keys.

## Registering Key Handlers

Use the `.onKeyPress()` modifier to handle keyboard events in your views:

### Handle All Keys

```swift
Text("Press any key")
    .onKeyPress { event in
        if event.key == .enter {
            doSomething()
            return true   // consumed — stops propagation
        }
        return false      // not consumed — passes to next handler
    }
```

### Handle Specific Keys

```swift
Text("Use arrow keys")
    .onKeyPress(keys: [.up, .down]) { event in
        if event.key == .up { moveUp() }
        else { moveDown() }
        return true
    }
```

### Handle a Single Key

The single-key variant always consumes the event:

```swift
Text("Press Enter to continue")
    .onKeyPress(.enter) {
        continueAction()
    }
```

### Handler Priority

Handlers are dispatched in **reverse registration order** — the deepest view in the tree (most recently registered) gets the event first. This means inner views can intercept events before outer views see them.

```swift
VStack {
    Text("Outer")
        .onKeyPress(.enter) {
            // Only reached if inner handler did NOT consume it
            print("outer enter")
        }
    Text("Inner")
        .onKeyPress(.enter) {
            // Gets the event FIRST
            print("inner enter")
        }
}
```

> Important: All key handlers are re-registered every render frame. If a view is not rendered (e.g. behind a conditional), its handlers are not active.

## Focus Navigation

The ``FocusManager`` handles two navigation keys:

| Key | Action |
|-----|--------|
| Tab | Move focus to the next focusable element (wraps around) |
| Shift+Tab | Move focus to the previous focusable element (wraps around) |

When an element is focused, all other key events are delegated to it first via `handleKeyEvent(_:)`. Only if the focused element doesn't consume the event does it propagate further.

Arrow keys are **not** handled by `FocusManager` itself — individual views (like ``Menu`` and ``Button``) handle arrows in their own key event handlers.

For more details, see <doc:FocusSystem>.

## Default Bindings

Layer 3 provides three built-in key bindings that work without any configuration:

| Key | Action | Condition |
|-----|--------|-----------|
| `q` / `Q` | Quit application | Only when ``QuitBehavior`` allows it |
| `t` / `T` | Cycle to next color theme | Only when theme cycling is enabled |
| `a` / `A` | Cycle to next appearance | Always active |

### Quit Behavior

The ``QuitBehavior`` enum controls when `q` is allowed to quit:

| Value | Behavior |
|-------|----------|
| `.always` | `q` quits from any screen (default) |
| `.rootOnly` | `q` only quits when no status bar context is pushed |

`.rootOnly` is useful for modal dialogs — push a status bar context for the dialog, and `q` will be blocked until the user dismisses it:

```swift
Dialog(title: "Confirm") {
    Text("Are you sure?")
} footer: {
    ButtonRow {
        Button("Yes") { confirm() }
        Button("No") { cancel() }
    }
}
.statusBarItems(context: "confirm-dialog") {
    StatusBarItem(shortcut: "y", label: "yes")
    StatusBarItem(shortcut: "n", label: "no")
}
```

## Status Bar Shortcuts

The status bar displays available shortcuts to the user. Use the ``Shortcut`` namespace for consistent, platform-standard symbols:

### Display Symbols

```swift
.statusBarItems {
    StatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "nav")
    StatusBarItem(shortcut: Shortcut.enter, label: "select", key: .enter)
    StatusBarItem(shortcut: Shortcut.escape, label: "back")
}
```

### Common Symbols

| Symbol | Constant | Description |
|--------|----------|-------------|
| `⎋` | `Shortcut.escape` | Escape |
| `↵` | `Shortcut.enter` | Enter |
| `⇥` | `Shortcut.tab` | Tab |
| `⇤` | `Shortcut.shiftTab` | Shift+Tab |
| `⌫` | `Shortcut.backspace` | Backspace |
| `⌦` | `Shortcut.delete` | Delete |
| `␣` | `Shortcut.space` | Space |
| `↑` | `Shortcut.arrowUp` | Arrow up |
| `↓` | `Shortcut.arrowDown` | Arrow down |
| `←` | `Shortcut.arrowLeft` | Arrow left |
| `→` | `Shortcut.arrowRight` | Arrow right |
| `↑↓` | `Shortcut.arrowsUpDown` | Vertical arrows |
| `←→` | `Shortcut.arrowsLeftRight` | Horizontal arrows |
| `↑↓←→` | `Shortcut.arrowsAll` | All arrows |
| `⌃` | `Shortcut.control` | Control modifier |
| `⇧` | `Shortcut.shift` | Shift modifier |
| `⌥` | `Shortcut.option` | Option / Alt |

### Shortcut Helpers

```swift
// Combine modifier + key: "⌃c"
Shortcut.combine(.control, "c")

// Ctrl+key display: "^c"
Shortcut.ctrl("c")

// Range display: "1-9"
Shortcut.range("1", "9")
```

### Common Shortcut Letters

| Constant | Value |
|----------|-------|
| `Shortcut.quit` | `q` |
| `Shortcut.yes` | `y` |
| `Shortcut.no` | `n` |
| `Shortcut.cancel` | `c` |
| `Shortcut.ok` | `o` |

### Automatic Key Matching

``StatusBarItem`` automatically derives the trigger key from the shortcut string when no explicit `key:` parameter is given:

- Symbol shortcuts (`⎋`, `↵`, `⇥`) map to their corresponding ``Key`` values
- Single-character shortcuts (`"q"`, `"y"`) map to `.character(thatChar)`
- Arrow combinations (`"↑↓"`) match **both** individual arrow keys
- Multi-character non-symbol strings are informational only (no trigger key)

```swift
// Automatic: shortcut "q" triggers on Key.character("q")
StatusBarItem(shortcut: "q", label: "quit") { quit() }

// Explicit: override the trigger key
StatusBarItem(shortcut: Shortcut.enter, label: "select", key: .enter) { select() }

// Informational: no action, no trigger
StatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "nav")
```

## Status Bar Context Stack

The status bar supports a context stack for temporary shortcut overrides — useful for modals and nested navigation:

```swift
// Set global items
.statusBarItems {
    StatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "nav")
    StatusBarItem(shortcut: Shortcut.enter, label: "select", key: .enter)
}

// Push context-specific items (e.g. for a dialog)
.statusBarItems(context: "my-dialog") {
    StatusBarItem(shortcut: "y", label: "yes") { confirm() }
    StatusBarItem(shortcut: "n", label: "no") { cancel() }
}
```

When a context is pushed, its items replace the global items in the display. System items (quit, theme, appearance) remain visible unless a user item uses the same shortcut string.

### System Items

Three system items are shown by default:

| Shortcut | Label | Order | Description |
|----------|-------|-------|-------------|
| `q` | quit | 900 | Quit the application |
| `a` | appearance | 910 | Cycle border appearance |
| `t` | theme | 920 | Cycle color theme |

System items appear on the right side of the status bar. They can be disabled individually:

```swift
// In your App
statusBar.showSystemItems = false       // Hide all system items
statusBar.showThemeItem = false         // Hide only theme cycling
statusBar.showAppearanceItem = false    // Hide only appearance cycling
```

## Topics

### Input Types

- ``Key``
- ``KeyEvent``
- ``QuitBehavior``

### Focus

- ``FocusManager``
- ``FocusState``
- ``Focusable``

### Status Bar

- ``StatusBar``
- ``StatusBarItem``
- ``StatusBarItemProtocol``
- ``Shortcut``
