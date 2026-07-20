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

import Dispatch

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
    public static func main() {
        _ = Task { @MainActor in
            do {
                let runner = AppRunner<Self>(app: Self())
                try await runner.run()
                exit(EXIT_SUCCESS)
            } catch {
                writeApplicationFailure(error)
                exit(EXIT_FAILURE)
            }
        }
        dispatchMain()
    }
}

/// Writes a best-effort runtime failure diagnostic to standard error.
private func writeApplicationFailure(_ error: any Error) {
    let bytes = Array("TUIkit application failed: \(error)\n".utf8)
    let systemCalls = TerminalSystemCalls.system

    bytes.withUnsafeBufferPointer { buffer in
        guard let baseAddress = buffer.baseAddress else { return }
        var written = 0

        while written < buffer.count {
            let result = systemCalls.write(
                STDERR_FILENO,
                baseAddress + written,
                buffer.count - written
            )
            if result > 0 {
                written += result
            } else if result < 0, systemCalls.errorCode() == EINTR {
                continue
            } else {
                return
            }
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
    func run() async throws {
        let inputHandler = makeInputHandler()
        let renderer = makeRenderer()
        let pulseTimer = PulseTimer(clock: tuiContext.clock)
        let cursorTimer = CursorTimer(clock: tuiContext.clock)
        let animationScheduler = RuntimeAnimationScheduler(
            clock: tuiContext.clock,
            eventChannel: eventChannel
        )

        await startRuntime(pulseTimer: pulseTimer, cursorTimer: cursorTimer)
        do {
            try throwPendingTerminalFailure()
            try render(
                using: renderer,
                pulseTimer: pulseTimer,
                cursorTimer: cursorTimer,
                animationScheduler: animationScheduler
            )
            try await processEvents(
                using: inputHandler,
                renderer: renderer,
                pulseTimer: pulseTimer,
                cursorTimer: cursorTimer,
                animationScheduler: animationScheduler
            )
        } catch {
            stopRuntime(
                pulseTimer: pulseTimer,
                cursorTimer: cursorTimer,
                animationScheduler: animationScheduler
            )
            throw error
        }

        stopRuntime(
            pulseTimer: pulseTimer,
            cursorTimer: cursorTimer,
            animationScheduler: animationScheduler
        )
        try throwPendingTerminalFailure()
    }
}

// MARK: - Private Helpers

private extension AppRunner {
    /// Creates the runtime's input dispatcher.
    func makeInputHandler() -> InputHandler {
        InputHandler(
            statusBar: statusBar,
            keyEventDispatcher: tuiContext.keyEventDispatcher,
            focusManager: focusManager,
            paletteManager: paletteManager,
            appearanceManager: appearanceManager,
            onQuit: { [eventChannel] in
                eventChannel.send(.shutdownRequested)
            }
        )
    }

    /// Creates the runtime's renderer.
    func makeRenderer() -> RenderLoop<A> {
        RenderLoop(
            app: app,
            terminal: terminal,
            statusBar: statusBar,
            appHeader: appHeader,
            focusManager: focusManager,
            paletteManager: paletteManager,
            appearanceManager: appearanceManager,
            tuiContext: tuiContext
        )
    }

    /// Installs event sources and prepares the terminal session.
    func startRuntime(pulseTimer: PulseTimer, cursorTimer: CursorTimer) async {
        if let signals {
            await signals.install(sendingTo: eventChannel)
        }
        inputSource?.start(sendingTo: eventChannel)
        terminal.enterAlternateScreen()
        terminal.hideCursor()
        terminal.enableRawMode()

        appState.observe { [eventChannel] in
            eventChannel.send(.renderRequested)
        }
        let runtimeFocusChangeHandler = focusManager.onFocusChange
        focusManager.onFocusChange = { [weak pulseTimer] in
            pulseTimer?.reset()
            runtimeFocusChangeHandler?()
        }
        pulseTimer.start()
        cursorTimer.start()
    }

    /// Cancels runtime work and restores the terminal deterministically.
    func stopRuntime(
        pulseTimer: PulseTimer,
        cursorTimer: CursorTimer,
        animationScheduler: RuntimeAnimationScheduler
    ) {
        animationScheduler.stop()
        pulseTimer.stop()
        cursorTimer.stop()
        inputSource?.stop()
        signals?.stop()
        eventChannel.finish()
        cleanup()
    }

    /// Serially consumes state, input, signal, and animation events.
    func processEvents(
        using inputHandler: InputHandler,
        renderer: RenderLoop<A>,
        pulseTimer: PulseTimer,
        cursorTimer: CursorTimer,
        animationScheduler: RuntimeAnimationScheduler
    ) async throws {
        try await withTaskCancellationHandler {
            var iterator = eventChannel.events.makeAsyncIterator()
            while let event = await iterator.next() {
                switch event {
                case .renderRequested:
                    guard appState.needsRender else { continue }
                    try render(
                        using: renderer,
                        pulseTimer: pulseTimer,
                        cursorTimer: cursorTimer,
                        animationScheduler: animationScheduler
                    )
                case .inputAvailable:
                    try processAvailableInput(using: inputHandler)
                case .terminalResized:
                    renderer.invalidateDiffCache()
                    try render(
                        using: renderer,
                        pulseTimer: pulseTimer,
                        cursorTimer: cursorTimer,
                        animationScheduler: animationScheduler
                    )
                case .animationDeadline:
                    try render(
                        using: renderer,
                        pulseTimer: pulseTimer,
                        cursorTimer: cursorTimer,
                        animationScheduler: animationScheduler
                    )
                case .shutdownRequested:
                    return
                }
            }
        } onCancel: { [eventChannel] in
            eventChannel.send(.shutdownRequested)
        }
    }

    /// Renders one frame and schedules only the animation work it exposes.
    func render(
        using renderer: RenderLoop<A>,
        pulseTimer: PulseTimer,
        cursorTimer: CursorTimer,
        animationScheduler: RuntimeAnimationScheduler
    ) throws {
        appState.didRender()
        renderer.render(pulsePhase: pulseTimer.phase, cursorTimer: cursorTimer)
        try throwPendingTerminalFailure()
        animationScheduler.schedule(after: nextAnimationInterval)
    }

    /// Returns the cadence required by currently visible focus animations.
    var nextAnimationInterval: Double? {
        if focusManager.hasTextInputFocus {
            return 0.05
        }
        if focusManager.currentFocused != nil || focusManager.activeSectionIdentifier != nil {
            return 0.1
        }
        return nil
    }

    /// Drains a bounded batch after the input descriptor becomes readable.
    func processAvailableInput(using inputHandler: InputHandler) throws {
        var eventsProcessed = 0
        let maxEventsPerBatch = 128

        while eventsProcessed < maxEventsPerBatch {
            let keyEvent = terminal.readKeyEvent()
            try throwPendingTerminalFailure()
            guard let keyEvent else { return }
            inputHandler.handle(keyEvent)
            eventsProcessed += 1
        }
    }

    /// Throws the first terminal I/O failure exposed by the concrete terminal.
    func throwPendingTerminalFailure() throws {
        guard let failureReporter = terminal as? any TerminalFailureReporting,
              let failure = failureReporter.takeIOFailure() else {
            return
        }
        throw failure
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
