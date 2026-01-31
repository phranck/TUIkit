# Status Bar

Configure the shortcut bar at the bottom of the terminal.

## Overview

The status bar is a persistent row at the bottom of the terminal that shows keyboard shortcuts and contextual information. It is always visible and updates every frame.

TUIkit provides two status bar styles — ``StatusBarStyle/compact`` (single-line, shortcuts only) and ``StatusBarStyle/bordered`` (bordered with title support).

## Architecture

The status bar system has three parts:

- **``StatusBarState``** — Manages the item stack, style, and event handling
- **``StatusBarItem``** — A single shortcut entry (key + label + action)
- **``StatusBar``** — The view that renders items into a ``FrameBuffer``

## Defining Status Bar Items

Use the `statusBarItems` modifier on your views to register shortcuts:

```swift
VStack {
    Text("My App")
}
.statusBarItems {
    StatusBarItem(.character("n"), label: "New") {
        // handle "n" key press
    }
    StatusBarItem(.character("d"), label: "Delete") {
        // handle "d" key press
    }
}
```

Items are registered per frame during rendering. When a view is removed from the tree, its items automatically disappear from the status bar.

## The Shortcut Enum

``Shortcut`` defines the key trigger for a status bar item:

| Shortcut | Display | Description |
|----------|---------|-------------|
| `.character("q")` | `q` | A single character key |
| `.tab` | `⇥` | Tab key |
| `.enter` | `↵` | Enter / Return |
| `.escape` | `⎋` | Escape key |
| `.backspace` | `⌫` | Backspace / Delete |
| `.arrows` | `↑↓` | Arrow keys |
| `.arrowsHorizontal` | `←→` | Left / Right arrows |
| `.arrowsVertical` | `↑↓` | Up / Down arrows |

## Context Stack

Status bar items use a **context stack**. When a dialog or menu opens, it can push its own items onto the stack. The status bar always shows the topmost context:

```swift
// Push a new context (e.g. when opening a dialog)
statusBar.pushContext()

// Add items to the new context
statusBar.addItem(StatusBarItem(.escape, label: "Close") { ... })

// Pop the context when the dialog closes
statusBar.popContext()
```

This means the main view's shortcuts are hidden while a modal is active, and automatically restored when it closes.

## System Items

TUIkit registers built-in system items automatically:

| Key | Label | Action |
|-----|-------|--------|
| `q` / `Ctrl+C` | Quit | Exit the application |
| `p` | Palette | Cycle to next color palette |
| `a` | Appearance | Cycle to next border appearance |

These appear on the right side of the status bar. You can configure quit behavior via ``QuitBehavior``.

## Status Bar Styles

Two styles are available:

- **``StatusBarStyle/compact``** — Items rendered as `key Label` pairs in a single line, no border
- **``StatusBarStyle/bordered``** — Items inside a bordered container

Set the style during app configuration or at runtime via the status bar state.

## Event Dispatch Priority

Status bar items are dispatched in **Layer 1** of the key event pipeline — they take priority over view-registered handlers and default bindings. See <doc:AppLifecycle> for the full dispatch order.
