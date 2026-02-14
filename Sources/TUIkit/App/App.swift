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
/// - `SignalManager` - POSIX signal handling (SIGINT, SIGWINCH)
/// - `InputHandler` - Key event dispatch (status bar, views, defaults)
/// - `RenderLoop` — Rendering pipeline (scene + status bar)
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
        self.paletteManager = ThemeManager(items: PaletteRegistry.all, renderTrigger: { [appState] in appState.setNeedsRender() })
        self.appearanceManager = ThemeManager(items: AppearanceRegistry.all, renderTrigger: { [appState] in appState.setNeedsRender() })

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
        let cursorTimer = CursorTimer(renderNotifier: appState)

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

        // Reset pulse animation and trigger re-render when focus changes
        focusManager.onFocusChange = { [weak pulseTimer, weak appState] in
            pulseTimer?.reset()
            appState?.setNeedsRender()
        }

        isRunning = true

        // Start animation timers
        pulseTimer.start()
        cursorTimer.start()

        // Initial render
        renderer.render(pulsePhase: pulseTimer.phase, cursorTimer: cursorTimer)

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
                renderer.render(pulsePhase: pulseTimer.phase, cursorTimer: cursorTimer)
            }

            // Read key events (non-blocking with VTIME=0)
            // Process all available events per frame. A high limit prevents
            // input buffering lag during paste operations while still avoiding
            // infinite loops if input arrives faster than we can process.
            var eventsProcessed = 0
            let maxEventsPerFrame = 128
            while eventsProcessed < maxEventsPerFrame,
                  let keyEvent = terminal.readKeyEvent() {
                inputHandler.handle(keyEvent)
                eventsProcessed += 1
            }

            // Sleep 28ms to yield CPU.
            // This sets the maximum frame rate to ~35 FPS.
            //
            usleep(28_000)
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
    /// The caller (`RenderLoop`) is responsible for writing the buffer
    /// to the terminal via `FrameDiffWriter`.
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
/// handled by `RenderLoop` via `FrameDiffWriter`.
///
/// Renders the window group's content view into a ``FrameBuffer``.
///
/// Like SwiftUI, `WindowGroup` centers its content both horizontally
/// and vertically within the available terminal space.
extension WindowGroup: SceneRenderable {
    func renderScene(context: RenderContext) -> FrameBuffer {
        let buffer = renderToBuffer(content, context: context)

        // Center the content in the available space, like SwiftUI does
        return centerBuffer(buffer, inWidth: context.availableWidth, height: context.availableHeight)
    }

    /// Centers a buffer within the target dimensions.
    private func centerBuffer(_ buffer: FrameBuffer, inWidth targetWidth: Int, height targetHeight: Int) -> FrameBuffer {
        // If buffer already fills the space exactly, return as-is
        if buffer.width == targetWidth && buffer.height == targetHeight {
            return buffer
        }

        var result: [String] = []
        result.reserveCapacity(targetHeight)

        // Calculate offsets for centering
        let verticalOffset = max(0, (targetHeight - buffer.height) / 2)
        let horizontalOffset = max(0, (targetWidth - buffer.width) / 2)
        let leftPadding = String(repeating: " ", count: horizontalOffset)

        // Add top padding (empty lines)
        for _ in 0..<verticalOffset {
            result.append(String(repeating: " ", count: targetWidth))
        }

        // Add content lines with horizontal centering
        for row in 0..<min(buffer.height, targetHeight - verticalOffset) {
            let line = buffer.lines[row]
            let rightPadding = max(0, targetWidth - horizontalOffset - line.strippedLength)
            result.append(leftPadding + line + String(repeating: " ", count: rightPadding))
        }

        // Add bottom padding (empty lines)
        let bottomPadding = max(0, targetHeight - verticalOffset - buffer.height)
        for _ in 0..<bottomPadding {
            result.append(String(repeating: " ", count: targetWidth))
        }

        return FrameBuffer(lines: result)
    }
}
