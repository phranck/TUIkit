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

        let renderer = ViewRenderer(terminal: terminal)

        // Extract the root view from the scene
        let scene = app.body
        renderScene(scene, with: renderer)
    }

    private func renderScene<S: TScene>(_ scene: S, with renderer: ViewRenderer) {
        if let renderable = scene as? SceneRenderable {
            renderable.renderScene(with: renderer)
        }
    }

    private func handleKeyEvent(_ event: KeyEvent) {
        // First, let registered handlers try to handle the event
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
    func renderScene(with renderer: ViewRenderer)
}

extension WindowGroup: SceneRenderable {
    func renderScene(with renderer: ViewRenderer) {
        renderer.render(content)
    }
}
