# Status Bar

Configure the shortcut bar at the bottom of the terminal.

## Overview

The status bar is a row at the bottom of the terminal that shows keyboard shortcuts and contextual information. It updates every frame while it has active items.

The status bar is hidden automatically when there are no active user items and no visible system items.

TUIkit provides two status bar styles: ``StatusBarStyle/compact`` (single-line, shortcuts only) and ``StatusBarStyle/bordered`` (bordered with title support).

## Architecture

The status bar system has three parts:

- **``StatusBarState``**: Manages the item stack, style, and event handling
- **``StatusBarItem``**: A single shortcut entry (key + label + action)
- **``StatusBar``**: The view that renders items into a ``FrameBuffer``

## Defining Status Bar Items

Use the `statusBarItems` modifier on your views to register shortcuts:

```swift
VStack {
    Text("My App")
}
.statusBarItems {
    StatusBarItem(shortcut: "n", label: "new") {
        // handle "n" key press
    }
    StatusBarItem(shortcut: "d", label: "delete") {
        // handle "d" key press
    }
}
```

Items are registered per frame during rendering. When a view is removed from the tree, its items automatically disappear from the status bar.

## Shortcut Display Symbols

Use ``Shortcut`` to keep displayed shortcut symbols consistent:

| Constant | Display | Description |
|----------|---------|-------------|
| `Shortcut.quit` | `q` | Default quit display |
| `Shortcut.enter` | `↵` | Enter / Return |
| `Shortcut.escape` | `⎋` | Escape |
| `Shortcut.tab` | `⇥` | Tab |
| `Shortcut.arrowUp` | `↑` | Arrow up |
| `Shortcut.arrowDown` | `↓` | Arrow down |
| `Shortcut.arrowsUpDown` | `↑↓` | Vertical navigation |
| `Shortcut.ctrl("q")` | `⌃q` | Ctrl+Q display |

`Shortcut` defines how the item is displayed. If you do not pass `key:`, `StatusBarItem` derives a trigger key from the shortcut string where possible.

## Context Stack

Status bar items use a **context stack**. Context-specific items can temporarily replace global items, for example while a dialog is visible:

```swift
Dialog(title: "Confirm") {
    Text("Delete file?")
} footer: {
    ButtonRow {
        Button("Delete") { delete() }
        Button("Cancel") { cancel() }
    }
}
.statusBarItems(context: "confirm-dialog") {
    StatusBarItem(shortcut: "y", label: "yes") { delete() }
    StatusBarItem(shortcut: "n", label: "no") { cancel() }
}
```

The topmost context replaces global user items in the display. System items remain visible unless a user item uses the same shortcut string.

## System Items

TUIkit registers built-in system items automatically:

| Key | Label | Action |
|-----|-------|--------|
| `q` | Quit | Exit the application |
| `a` | Appearance | Cycle to next border appearance |
| `t` | Theme | Cycle to next color theme |

These appear on the right side of the status bar. Only `q quit` is shown by default. Enable `a appearance` and `t theme` with the ``View/statusBarSystemItems(theme:appearance:)`` modifier.

### Overriding `q quit`

A user-defined status bar item with shortcut `q` overrides the built-in quit binding for that view context:

```swift
EditorView()
    .statusBarItems {
        StatusBarItem(shortcut: "q", label: "close") {
            closeEditor()
        }
    }
```

This works because status bar items with actions are handled before the default quit binding. The built-in `q quit` system item is also removed from the display when a user item uses the same shortcut string.

### Changing the global quit shortcut

Change the built-in quit key through ``StatusBarState/quitShortcut``:

```swift
@main
struct MyApp: App {
    @Environment(\.statusBar) private var statusBar

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .task {
            statusBar.quitShortcut = .escape
        }
    }
}
```

Available presets include ``QuitShortcut/q``, ``QuitShortcut/escape``, ``QuitShortcut/ctrlQ``, and ``QuitShortcut/ctrlC``. You can also create a fully custom ``QuitShortcut``.

### Hiding the status bar completely

Hide all system items and do not register any user items:

```swift
ContentView()
    .statusBarSystemItems(theme: false, appearance: false)
```

```swift
@Environment(\.statusBar) private var statusBar

statusBar.showSystemItems = false
```

When there are no active items left, the status bar height becomes zero and it is not rendered.

## Status Bar Styles

Two styles are available:

- **``StatusBarStyle/compact``**: Items rendered as `key Label` pairs in a single line, no border
- **``StatusBarStyle/bordered``**: Items inside a bordered container

Set the style during app configuration or at runtime via the status bar state.

## Event Dispatch Priority

Status bar items are dispatched in **Layer 1** of the key event pipeline: they take priority over view-registered handlers and default bindings. See <doc:AppLifecycle> for the full dispatch order.
