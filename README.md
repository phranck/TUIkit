![Swift 6.2](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)
![macOS](https://img.shields.io/badge/Platform-macOS-000000?logo=apple&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue)
![Status](https://img.shields.io/badge/Status-Work_in_Progress-yellow)

# SwiftTUI

A SwiftUI-like framework for building Terminal User Interfaces in Swift — no ncurses, no C dependencies, just pure Swift.

## What is this?

SwiftTUI lets you build TUI apps using the same declarative syntax you already know from SwiftUI. Define your UI with `TView`, compose views with `VStack`, `HStack`, and `ZStack`, style text with modifiers like `.bold()` and `.foregroundColor(.red)`, and run it all in your terminal.

```swift
struct ContentView: TView {
    var body: some TView {
        VStack(spacing: 1) {
            Text("Hello, SwiftTUI!")
                .bold()
                .foregroundColor(.cyan)
            Divider()
            HStack {
                Text("Status:")
                Text("Running").foregroundColor(.green)
            }
        }
    }
}
```

## Features

- **`TView` protocol** — the core building block, mirroring SwiftUI's `View`
- **`@TViewBuilder`** — result builder for declarative view composition (up to 10 children, conditionals, optionals, loops)
- **Primitive views** — `Text`, `EmptyView`, `Spacer`, `Divider`
- **Layout containers** — `VStack`, `HStack`, `ZStack` with alignment and spacing
- **`ForEach`** — iterate over collections, ranges, or `Identifiable` data
- **Text styling** — bold, italic, underline, strikethrough, dim, blink, inverted
- **Full color support** — 8 standard ANSI colors, bright variants, 256-color palette, 24-bit RGB, hex values
- **Terminal abstraction** — raw mode, cursor control, alternate screen buffer
- **`TApp` protocol** — app lifecycle with signal handling and run loop

## Run the Example App

```bash
swift run SwiftTUIExample
```

Press `q` or `ESC` to exit.

## Developer Notes

- **Swift 6.2** with strict concurrency is required (swift-tools-version 6.2)
- **macOS only** — this is a terminal framework, iOS/watchOS/tvOS don't apply
- The rendering engine uses **pure ANSI escape codes** — no external dependencies
- `TView` is a **protocol** (not a class), so views are value types by default
- Primitive views (`Text`, `Spacer`, `Divider`, stacks, etc.) conform to the internal `Renderable` protocol for direct terminal output
- Composite views just define a `body` and the renderer walks the tree recursively
- The `Terminal` class handles raw mode, screen buffer switching, and cursor control via POSIX `termios`
- Tests use Swift Testing (`@Test`, `#expect`) — run with `swift test`

## Project Structure

```
Sources/
├── SwiftTUI/
│   ├── App/              TApp, TScene, WindowGroup
│   ├── Core/             TView, TViewBuilder, Color, TupleViews, PrimitiveViews
│   ├── Rendering/        Terminal, ANSIRenderer, ViewRenderer, Renderable
│   └── Views/            Text, Stacks, Spacer, Divider, ForEach
└── SwiftTUIExample/      Example app (executable target)
```

## License

MIT
