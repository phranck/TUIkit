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

        isRunning = true

        // Initial render
        render()

        // Main loop
        while isRunning {
            // Check if terminal was resized
            if needsRerender {
                needsRerender = false
                render()
            }

            if let char = terminal.readChar() {
                handleInput(char)
            }
        }

        // Cleanup
        cleanup()
    }

    private func render() {
        terminal.clear()
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

    private func handleInput(_ char: Character) {
        // Escape or 'q' exits the app
        if char == "\u{1B}" || char == "q" || char == "Q" {
            isRunning = false
        }
    }

    private func cleanup() {
        terminal.disableRawMode()
        terminal.showCursor()
        terminal.exitAlternateScreen()
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
