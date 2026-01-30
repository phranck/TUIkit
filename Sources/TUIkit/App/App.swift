//
//  App.swift
//  TUIkit
//
//  The base protocol for TUIkit applications.
//

import Foundation

// MARK: - App Protocol

/// The base protocol for TUIkit applications.
///
/// `App` is the entry point for every TUIkit application,
/// similar to `App` in SwiftUI.
///
/// # Example
///
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///     }
/// }
/// ```
public protocol App {
    /// The type of the main scene.
    associatedtype Body: Scene

    /// The main scene of the app.
    @SceneBuilder
    var body: Body { get }

    /// Initializes the app.
    init()
}

extension App {
    /// Starts the app.
    ///
    /// This method is called by the `@main` attribute and starts
    /// the main run loop of the application.
    public static func main() {
        let app = Self()
        let runner = AppRunner<Self>(app: app)
        runner.run()
    }
}

// MARK: - App Runner

/// Runs an App.
///
/// `AppRunner` is the main coordinator that owns the run loop and
/// delegates to specialized managers:
/// - ``SignalManager`` — POSIX signal handling (SIGINT, SIGWINCH)
/// - ``InputHandler`` — Key event dispatch (status bar → views → defaults)
/// - ``RenderLoop`` — Rendering pipeline (scene + status bar)
internal final class AppRunner<A: App> {
    let app: A
    let terminal: Terminal
    let statusBar: StatusBarState
    let focusManager: FocusManager
    let paletteManager: ThemeManager
    let appearanceManager: ThemeManager
    let tuiContext: TUIContext
    private var signals = SignalManager()
    private var inputHandler: InputHandler!
    private var renderer: RenderLoop<A>!
    private var isRunning = false

    init(app: A) {
        self.app = app
        self.terminal = Terminal()
        self.statusBar = StatusBarState()
        self.focusManager = FocusManager()
        self.tuiContext = TUIContext()
        self.paletteManager = ThemeManager(
            items: PaletteRegistry.all,
            applyToEnvironment: { item in
                if let palette = item as? any Palette {
                    EnvironmentStorage.shared.environment.palette = palette
                }
            }
        )
        self.appearanceManager = ThemeManager(
            items: AppearanceRegistry.all,
            applyToEnvironment: { item in
                if let appearance = item as? Appearance {
                    EnvironmentStorage.shared.environment.appearance = appearance
                }
            }
        )

        // Configure status bar style
        self.statusBar.style = .bordered

        // These reference self or other stored properties,
        // so they are created after all stored properties are initialized.
        self.inputHandler = InputHandler(
            statusBar: statusBar,
            keyEventDispatcher: tuiContext.keyEventDispatcher,
            paletteManager: paletteManager,
            appearanceManager: appearanceManager,
            onQuit: { [weak self] in
                self?.isRunning = false
            }
        )
        self.renderer = RenderLoop(
            app: app,
            terminal: terminal,
            statusBar: statusBar,
            focusManager: focusManager,
            paletteManager: paletteManager,
            appearanceManager: appearanceManager,
            tuiContext: tuiContext
        )
    }

    func run() {
        // Setup
        signals.install()
        terminal.enterAlternateScreen()
        terminal.hideCursor()
        terminal.enableRawMode()

        // Set up environment with all managed subsystems
        EnvironmentStorage.shared.environment = renderer.buildEnvironment()

        // Register for state changes
        AppState.shared.observe { [signals] in
            signals.requestRerender()
        }

        isRunning = true

        // Initial render
        renderer.render()

        // Main loop
        while isRunning {
            // Check for graceful shutdown request (from SIGINT handler)
            if signals.shouldShutdown {
                isRunning = false
                break
            }

            // Check if terminal was resized or state changed
            if signals.consumeRerenderFlag() || AppState.shared.needsRender {
                AppState.shared.didRender()
                renderer.render()
            }

            // Read key events
            if let keyEvent = terminal.readKeyEvent() {
                inputHandler.handle(keyEvent)
            }
        }

        // Cleanup
        cleanup()
    }

    private func cleanup() {
        terminal.disableRawMode()
        terminal.showCursor()
        terminal.exitAlternateScreen()
        AppState.shared.clearObservers()
        EnvironmentStorage.shared.reset()
        focusManager.clear()
        tuiContext.reset()
    }

}

// MARK: - Scene Rendering Protocol

/// Bridge from the `Scene` hierarchy to the `View` rendering system.
///
/// `SceneRenderable` sits outside the `View`/`Renderable` dual system.
/// It connects the `App.body` (which produces a `Scene`) to the view
/// tree rendering via ``renderToBuffer(_:context:)``.
///
/// `RenderLoop` calls `renderScene(context:)` on the scene returned
/// by `App.body`. The scene (typically ``WindowGroup``) then invokes
/// the free function `renderToBuffer` on its content view, entering
/// the standard `Renderable`-or-`body` dispatch.
internal protocol SceneRenderable {
    /// Renders the scene's content to the terminal.
    ///
    /// - Parameter context: The rendering context with layout constraints.
    func renderScene(context: RenderContext)
}

/// Renders the window group's content view to the terminal.
///
/// This is the bridge from `Scene` to `View` rendering:
/// calls ``renderToBuffer(_:context:)`` on `content`, writes the
/// resulting ``FrameBuffer`` line-by-line with persistent background.
extension WindowGroup: SceneRenderable {
    func renderScene(context: RenderContext) {
        let buffer = renderToBuffer(content, context: context)
        let terminal = context.terminal
        let terminalWidth = terminal.width
        let terminalHeight = context.availableHeight

        // Get background color from palette
        let bgColor = context.environment.palette.background
        let bgCode = ANSIRenderer.backgroundCode(for: bgColor)
        let reset = ANSIRenderer.reset

        // Write buffer to terminal, ensuring consistent background color
        for row in 0..<terminalHeight {
            terminal.moveCursor(toRow: 1 + row, column: 1)

            if row < buffer.lines.count {
                let line = buffer.lines[row]
                let visibleWidth = line.strippedLength
                let padding = max(0, terminalWidth - visibleWidth)

                // Replace all reset codes with "reset + restore background"
                // This ensures background color persists after styled text
                let lineWithBg = line.replacingOccurrences(of: reset, with: reset + bgCode)

                // Wrap entire line with background
                let paddedLine = bgCode + lineWithBg + String(repeating: " ", count: padding) + reset
                terminal.write(paddedLine)
            } else {
                // Empty row - fill with background color
                let emptyLine = bgCode + String(repeating: " ", count: terminalWidth) + reset
                terminal.write(emptyLine)
            }
        }
    }
}
