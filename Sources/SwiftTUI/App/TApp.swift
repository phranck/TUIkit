//
//  TApp.swift
//  SwiftTUI
//
//  The base protocol for SwiftTUI applications.
//

import Foundation

/// The base protocol for SwiftTUI applications.
///
/// `TApp` is the entry point for every SwiftTUI application,
/// similar to `App` in SwiftUI.
///
/// # Example
///
/// ```swift
/// @main
/// struct MyApp: TApp {
///     var body: some TScene {
///         WindowGroup {
///             ContentView()
///         }
///     }
/// }
/// ```
public protocol TApp {
    /// The type of the main scene.
    associatedtype Body: TScene

    /// The main scene of the app.
    @SceneBuilder
    var body: Body { get }

    /// Initializes the app.
    init()
}

extension TApp {
    /// Starts the app.
    ///
    /// This method is called by the `@main` attribute and starts
    /// the main run loop of the application.
    public static func main() {
        let app = Self()
        let runner = AppRunner(app: app)
        runner.run()
    }
}

/// Flag set by the SIGWINCH signal handler to request a re-render.
/// Must be an atomic type safe for signal context.
private nonisolated(unsafe) var needsRerender = false

/// Runs a TApp.
internal final class AppRunner<App: TApp> {
    let app: App
    let terminal: Terminal
    private var isRunning = false

    init(app: App) {
        self.app = app
        self.terminal = Terminal.shared
    }

    func run() {
        // Setup
        setupSignalHandlers()
        terminal.enterAlternateScreen()
        terminal.hideCursor()
        terminal.enableRawMode()

        // Register for state changes
        AppState.shared.observe { [weak self] in
            needsRerender = true
            _ = self  // Silence warning
        }

        isRunning = true

        // Initial render
        render()

        // Main loop
        while isRunning {
            // Check if terminal was resized or state changed
            if needsRerender || AppState.shared.needsRender {
                needsRerender = false
                AppState.shared.didRender()
                render()
            }

            // Read key events
            if let keyEvent = terminal.readKeyEvent() {
                handleKeyEvent(keyEvent)
            }
        }

        // Cleanup
        cleanup()
    }

    private func render() {
        terminal.clear()

        // Clear event handlers before re-rendering
        KeyEventDispatcher.shared.clearHandlers()
        FocusManager.shared.clear()

        // Calculate available height (reserve space for status bar)
        let statusBarHeight = StatusBarManager.shared.hasItems
            ? (StatusBarManager.shared.style == .bordered ? 3 : 1)
            : 0
        let contentHeight = terminal.height - statusBarHeight

        // Create renderer with adjusted height
        let context = RenderContext(
            terminal: terminal,
            availableWidth: terminal.width,
            availableHeight: contentHeight
        )

        // Render main content
        let scene = app.body
        renderScene(scene, context: context)

        // Render status bar separately (never dimmed)
        if StatusBarManager.shared.hasItems {
            renderStatusBar(atRow: terminal.height - statusBarHeight + 1)
        }
    }

    private func renderScene<S: TScene>(_ scene: S, context: RenderContext) {
        if let renderable = scene as? SceneRenderable {
            renderable.renderScene(context: context)
        }
    }

    /// Renders the status bar at the specified row.
    private func renderStatusBar(atRow row: Int) {
        let statusBar = TStatusBar()
        let context = RenderContext(
            terminal: terminal,
            availableWidth: terminal.width,
            availableHeight: statusBar.height
        )

        let buffer = renderToBuffer(statusBar, context: context)

        // Write directly to terminal at the bottom
        for (index, line) in buffer.lines.enumerated() {
            terminal.moveCursor(toRow: row + index, column: 1)
            terminal.write(line)
        }
    }

    private func handleKeyEvent(_ event: KeyEvent) {
        // First, let the status bar handle the event
        if StatusBarManager.shared.handleKeyEvent(event) {
            return
        }

        // Then, let registered handlers try to handle the event
        if KeyEventDispatcher.shared.dispatch(event) {
            return
        }

        // Default handling (only if no handler consumed the event):
        // - ESC exits the app
        // - 'q' or 'Q' exits the app
        switch event.key {
        case .escape:
            isRunning = false
        case .character(let char) where char == "q" || char == "Q":
            isRunning = false
        default:
            break
        }
    }

    private func cleanup() {
        terminal.disableRawMode()
        terminal.showCursor()
        terminal.exitAlternateScreen()
        AppState.shared.clearObservers()
        KeyEventDispatcher.shared.clearHandlers()
        StatusBarManager.shared.clear()
        FocusManager.shared.clear()
    }

    private func setupSignalHandlers() {
        // Catch SIGINT (Ctrl+C)
        signal(SIGINT) { _ in
            Terminal.shared.disableRawMode()
            Terminal.shared.showCursor()
            Terminal.shared.exitAlternateScreen()
            exit(0)
        }

        // Catch SIGWINCH (terminal size change) — sets a flag
        // that the main loop picks up safely.
        signal(SIGWINCH) { _ in
            needsRerender = true
        }
    }
}

// MARK: - Scene Rendering Protocol

/// Internal protocol for renderable scenes.
internal protocol SceneRenderable {
    func renderScene(context: RenderContext)
}

extension WindowGroup: SceneRenderable {
    func renderScene(context: RenderContext) {
        let buffer = renderToBuffer(content, context: context)
        // Write buffer to terminal
        let terminal = Terminal.shared
        for (index, line) in buffer.lines.enumerated() {
            terminal.moveCursor(toRow: 1 + index, column: 1)
            terminal.write(line)
        }
    }
}
