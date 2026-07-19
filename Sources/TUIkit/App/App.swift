//  🖥️ TUIKit — Terminal UI Kit for Swift
//  App.swift
//
//  Created by LAYERED.work
//  License: MIT

#if canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Darwin)
    import Darwin
#endif

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
    public static func main() async {
        let app = Self()
        let runner = AppRunner<Self>(app: app)
        await runner.run()
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
    private let appearanceManager: ThemeManager
    private let appHeader: AppHeaderState
    private let appState: AppState
    private let focusManager: FocusManager
    private let paletteManager: ThemeManager
    private let statusBar: StatusBarState
    private let terminal: any TerminalProtocol
    private let tuiContext: TUIContext
    private let eventChannel: RuntimeEventChannel
    private let inputSource: TerminalInputSource?
    private let signals: SignalManager?

    init(
        app: A,
        terminal: (any TerminalProtocol)? = nil,
        tuiContext: TUIContext? = nil,
        eventChannel: RuntimeEventChannel = RuntimeEventChannel(),
        inputSource: TerminalInputSource? = TerminalInputSource(),
        signals: SignalManager? = SignalManager()
    ) {
        let tuiContext = tuiContext ?? TUIContext.production()
        self.app = app
        self.appState = tuiContext.appState
        self.appearanceManager = tuiContext.appearanceManager
        self.appHeader = tuiContext.appHeader
        self.focusManager = tuiContext.focusManager
        self.paletteManager = tuiContext.paletteManager
        self.statusBar = tuiContext.statusBar
        self.statusBar.style = .bordered
        self.terminal = terminal ?? Terminal()
        self.tuiContext = tuiContext
        self.eventChannel = eventChannel
        self.inputSource = inputSource
        self.signals = signals
    }
}

// MARK: - Internal API

extension AppRunner {
    func run() async {
        // Create run-loop dependencies (previously IUOs, now local variables)
        let inputHandler = InputHandler(
            statusBar: statusBar,
            keyEventDispatcher: tuiContext.keyEventDispatcher,
            focusManager: focusManager,
            paletteManager: paletteManager,
            appearanceManager: appearanceManager,
            onQuit: { [eventChannel] in
                eventChannel.send(.shutdownRequested)
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
        if let signals {
            await signals.install(sendingTo: eventChannel)
        }
        inputSource?.start(sendingTo: eventChannel)
        terminal.enterAlternateScreen()
        terminal.hideCursor()
        terminal.enableRawMode()

        // Register for state changes
        appState.observe { [eventChannel] in
            eventChannel.send(.renderRequested)
        }

        // Reset pulse animation and trigger re-render when focus changes
        let runtimeFocusChangeHandler = focusManager.onFocusChange
        focusManager.onFocusChange = { [weak pulseTimer] in
            pulseTimer?.reset()
            runtimeFocusChangeHandler?()
        }

        // Start animation timers
        pulseTimer.start()
        cursorTimer.start()

        // Initial render
        appState.didRender()
        renderer.render(pulsePhase: pulseTimer.phase, cursorTimer: cursorTimer)

        defer {
            pulseTimer.stop()
            cursorTimer.stop()
            inputSource?.stop()
            signals?.stop()
            eventChannel.finish()
            cleanup()
        }

        await withTaskCancellationHandler {
            var iterator = eventChannel.events.makeAsyncIterator()
            while let event = await iterator.next() {
                switch event {
                case .renderRequested:
                    guard appState.needsRender else { continue }
                    appState.didRender()
                    renderer.render(pulsePhase: pulseTimer.phase, cursorTimer: cursorTimer)

                case .inputAvailable:
                    processAvailableInput(using: inputHandler)

                case .terminalResized:
                    renderer.invalidateDiffCache()
                    appState.didRender()
                    renderer.render(pulsePhase: pulseTimer.phase, cursorTimer: cursorTimer)

                case .shutdownRequested:
                    return
                }
            }
        } onCancel: { [eventChannel] in
            eventChannel.send(.shutdownRequested)
        }
    }
}

// MARK: - Private Helpers

private extension AppRunner {
    /// Drains a bounded batch after the input descriptor becomes readable.
    func processAvailableInput(using inputHandler: InputHandler) {
        var eventsProcessed = 0
        let maxEventsPerBatch = 128

        while eventsProcessed < maxEventsPerBatch,
              let keyEvent = terminal.readKeyEvent() {
            inputHandler.handle(keyEvent)
            eventsProcessed += 1
        }
    }

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
