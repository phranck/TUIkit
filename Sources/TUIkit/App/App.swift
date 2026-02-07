//  🖥️ TUIKit — Terminal UI Kit for Swift
//  App.swift
//
//  Created by LAYERED.work
//  License: MIT

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
@MainActor
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
    ///
    /// Since TUIKit runs on the main thread and `@main` entry points
    /// execute on the main thread, we use `MainActor.assumeIsolated`
    /// to access MainActor-isolated types synchronously.
    public static func main() {
        MainActor.assumeIsolated {
            let app = Self()
            let runner = AppRunner<Self>(app: app)
            runner.run()
        }
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
@MainActor
internal final class AppRunner<A: App> {
    private let app: A
    private let terminal: Terminal
    private let appState: AppState
    private let statusBar: StatusBarState
    private let appHeader: AppHeaderState
    private let focusManager: FocusManager
    private let paletteManager: ThemeManager
    private let appearanceManager: ThemeManager
    private let tuiContext: TUIContext
    private var signals = SignalManager()
    private var isRunning = false

    init(app: A) {
        self.app = app
        self.terminal = Terminal()
        self.appState = AppState()
        self.statusBar = StatusBarState(appState: appState)
        self.appHeader = AppHeaderState()
        self.focusManager = FocusManager()
        self.tuiContext = TUIContext()
        self.paletteManager = ThemeManager(items: PaletteRegistry.all, appState: appState)
        self.appearanceManager = ThemeManager(items: AppearanceRegistry.all, appState: appState)

        // Configure status bar style
        self.statusBar.style = .bordered
    }
}

// MARK: - Internal API

extension AppRunner {
    func run() {
        // Create run-loop dependencies (previously IUOs, now local variables)
        let inputHandler = InputHandler(
            statusBar: statusBar,
            keyEventDispatcher: tuiContext.keyEventDispatcher,
            focusManager: focusManager,
            paletteManager: paletteManager,
            appearanceManager: appearanceManager,
            onQuit: { [weak self] in
                self?.isRunning = false
            }
        )
        let renderer = RenderLoop(
            app: app,
            terminal: terminal,
            statusBar: statusBar,
            appHeader: appHeader,
            focusManager: focusManager,
            paletteManager: paletteManager,
            appearanceManager: appearanceManager,
            tuiContext: tuiContext
        )
        let pulseTimer = PulseTimer(renderNotifier: appState)

        // Setup
        signals.install()
        terminal.enterAlternateScreen()
        terminal.hideCursor()
        terminal.enableRawMode()

        // Register AppState and RenderCache with framework-internal notifier for property wrappers
        RenderNotifier.current = appState
        RenderNotifier.renderCache = tuiContext.renderCache

        // Register for state changes
        appState.observe { [signals] in
            signals.requestRerender()
        }

        // Reset pulse animation when focus changes
        focusManager.onFocusChange = { [weak pulseTimer] in
            pulseTimer?.reset()
        }

        isRunning = true

        // Start the breathing focus indicator animation
        pulseTimer.start()

        // Initial render
        renderer.render(pulsePhase: pulseTimer.phase)

        // Main loop
        while isRunning {
            // Check for graceful shutdown request (from SIGINT handler)
            if signals.shouldShutdown {
                isRunning = false
                break
            }

            // Invalidate diff cache on terminal resize so every line
            // is rewritten with the new dimensions.
            if signals.consumeResizeFlag() {
                renderer.invalidateDiffCache()
            }

            // Check if terminal was resized or state changed
            if signals.consumeRerenderFlag() || appState.needsRender {
                appState.didRender()
                renderer.render(pulsePhase: pulseTimer.phase)
            }

            // Read key events (non-blocking with VTIME=0)
            if let keyEvent = terminal.readKeyEvent() {
                inputHandler.handle(keyEvent)
            }

            // Sleep 40ms to yield CPU (replaces VTIME=1 blocking read).
            // This sets the maximum frame rate to ~25 FPS.
            usleep(40_000)
        }

        // Stop pulse timer before cleanup
        pulseTimer.stop()

        // Cleanup
        cleanup()
    }
}

// MARK: - Private Helpers

private extension AppRunner {
    func cleanup() {
        terminal.disableRawMode()
        terminal.showCursor()
        terminal.exitAlternateScreen()
        appState.clearObservers()
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
@MainActor
internal protocol SceneRenderable {
    /// Renders the scene's content into a ``FrameBuffer``.
    ///
    /// The caller (``RenderLoop``) is responsible for writing the buffer
    /// to the terminal via ``FrameDiffWriter``.
    ///
    /// - Parameter context: The rendering context with layout constraints.
    /// - Returns: The rendered frame buffer.
    func renderScene(context: RenderContext) -> FrameBuffer
}

/// Renders the window group's content view into a ``FrameBuffer``.
///
/// This is the bridge from `Scene` to `View` rendering:
/// calls ``renderToBuffer(_:context:)`` on `content` and returns the
/// resulting ``FrameBuffer``. Terminal output (diffing, writing) is
/// handled by ``RenderLoop`` via ``FrameDiffWriter``.
extension WindowGroup: SceneRenderable {
    func renderScene(context: RenderContext) -> FrameBuffer {
        renderToBuffer(content, context: context)
    }
}
