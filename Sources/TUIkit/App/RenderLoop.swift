//
//  RenderLoop.swift
//  TUIkit
//
//  Manages the rendering pipeline: scene rendering, environment
//  assembly, and status bar output.
//

// MARK: - Render Loop

/// Manages the full rendering pipeline for each frame.
///
/// `RenderLoop` is owned by ``AppRunner`` and called once per frame.
/// It orchestrates the complete render pass from `App.body` to
/// terminal output.
///
/// ## Pipeline steps (per frame)
///
/// ```
/// render()
///   1. Clear per-frame state (key handlers, preferences, focus)
///   2. Begin lifecycle tracking
///   3. Build EnvironmentValues from all subsystems
///   4. Create RenderContext with layout constraints
///   5. Evaluate App.body fresh → Scene (WindowGroup)
///      @State values survive because State.init self-hydrates from StateStorage
///   6. Call SceneRenderable.renderScene() → FrameBuffer
///   7. Convert FrameBuffer to terminal-ready output lines
///   8. Begin buffered frame (terminal.beginFrame())
///   9. Diff against previous frame, write only changed lines to buffer
///  10. Render status bar into same buffer (with its own diff tracking)
///  11. Flush entire frame in one write() syscall (terminal.endFrame())
///  12. End lifecycle tracking (fires onDisappear for removed views)
/// ```
///
/// ## Diff-Based Rendering
///
/// `RenderLoop` uses a ``FrameDiffWriter`` to compare each frame's output
/// with the previous frame. Only lines that actually changed are written
/// to the terminal, reducing I/O by ~94% for mostly-static UIs.
///
/// ## Output Buffering
///
/// All diff writes (content + status bar) are collected in ``Terminal``'s
/// frame buffer and flushed as a single `write()` syscall via
/// ``Terminal/beginFrame()`` / ``Terminal/endFrame()``. This reduces
/// per-frame syscalls from ~40+ to exactly 1.
///
/// On terminal resize (SIGWINCH), the diff cache is invalidated to force
/// a full repaint.
///
/// ## Responsibilities
///
/// - Assembling ``EnvironmentValues`` from all subsystems
/// - Rendering the main scene content via ``SceneRenderable``
/// - Rendering the status bar separately (never dimmed)
/// - Coordinating lifecycle tracking (appear/disappear)
/// - Diff-based terminal output via ``FrameDiffWriter``
/// - Buffered frame output via ``Terminal``
internal final class RenderLoop<A: App> {
    /// The user's app instance (provides `body`).
    let app: A

    /// The terminal for output and size queries.
    let terminal: Terminal

    /// The status bar state (height, items, appearance).
    let statusBar: StatusBarState

    /// The focus manager (cleared each frame).
    let focusManager: FocusManager

    /// The palette manager (current theme for environment).
    let paletteManager: ThemeManager

    /// The appearance manager (current border style for environment).
    let appearanceManager: ThemeManager

    /// The central dependency container (lifecycle, key dispatch, preferences).
    let tuiContext: TUIContext

    /// The diff writer that tracks previous frames and writes only changed lines.
    private let diffWriter = FrameDiffWriter()

    init(
        app: A,
        terminal: Terminal,
        statusBar: StatusBarState,
        focusManager: FocusManager,
        paletteManager: ThemeManager,
        appearanceManager: ThemeManager,
        tuiContext: TUIContext
    ) {
        self.app = app
        self.terminal = terminal
        self.statusBar = statusBar
        self.focusManager = focusManager
        self.paletteManager = paletteManager
        self.appearanceManager = appearanceManager
        self.tuiContext = tuiContext
    }

    // MARK: - Rendering

    /// Performs a full render pass: scene content + status bar.
    ///
    /// See the class-level documentation for the complete pipeline steps.
    ///
    /// - Parameter pulsePhase: The current breathing indicator phase (0–1).
    ///   Passed from ``PulseTimer`` via ``AppRunner``.
    func render(pulsePhase: Double = 0) {
        // Clear per-frame state before re-rendering
        tuiContext.keyEventDispatcher.clearHandlers()
        tuiContext.preferences.beginRenderPass()
        focusManager.beginRenderPass()
        statusBar.clearSectionItems()

        // Provide the focus manager to the status bar for section resolution
        statusBar.focusManager = focusManager

        // Begin lifecycle and state tracking for this render pass
        tuiContext.lifecycle.beginRenderPass()
        tuiContext.stateStorage.beginRenderPass()

        // Calculate available height (reserve space for status bar).
        // Single getSize() call — avoids 2 ioctl syscalls per frame.
        let terminalSize = terminal.getSize()
        let statusBarHeight = statusBar.height
        let terminalWidth = terminalSize.width
        let terminalHeight = terminalSize.height
        let contentHeight = terminalHeight - statusBarHeight

        // Create render context with environment
        let environment = buildEnvironment()

        var context = RenderContext(
            availableWidth: terminalWidth,
            availableHeight: contentHeight,
            environment: environment,
            tuiContext: tuiContext
        )
        context.pulsePhase = pulsePhase

        // Render main content into a FrameBuffer.
        // app.body is evaluated fresh each frame. @State values survive
        // because State.init self-hydrates from StateStorage.
        //
        // We set the hydration context BEFORE evaluating app.body so that
        // views constructed inside WindowGroup { ... } closures (e.g.
        // ContentView()) get persistent state from the start.
        let rootIdentity = ViewIdentity(rootType: A.self)
        StateRegistration.activeContext = HydrationContext(
            identity: rootIdentity,
            storage: tuiContext.stateStorage
        )
        StateRegistration.counter = 0

        let scene = app.body

        StateRegistration.activeContext = nil
        tuiContext.stateStorage.markActive(rootIdentity)

        let buffer = renderScene(scene, context: context.withChildIdentity(type: type(of: scene)))

        // Validate focus state: if previously active section or focused element
        // is no longer in the tree, fall back to first available.
        focusManager.endRenderPass()

        // Build terminal-ready output lines and write only changes.
        // All terminal writes between beginFrame/endFrame are collected
        // in an internal buffer and flushed as a single write() syscall.
        let bgColor = environment.palette.background
        let bgCode = ANSIRenderer.backgroundCode(for: bgColor)
        let reset = ANSIRenderer.reset

        let outputLines = diffWriter.buildOutputLines(
            buffer: buffer,
            terminalWidth: terminalWidth,
            terminalHeight: contentHeight,
            bgCode: bgCode,
            reset: reset
        )

        terminal.beginFrame()
        diffWriter.writeContentDiff(
            newLines: outputLines,
            terminal: terminal,
            startRow: 1
        )

        // Render status bar inside the same frame (flushed together)
        if statusBar.hasItems {
            renderStatusBar(
                atRow: terminalHeight - statusBarHeight + 1,
                terminalWidth: terminalWidth,
                bgCode: bgCode,
                reset: reset
            )
        }
        terminal.endFrame()

        // End lifecycle tracking - triggers onDisappear for removed views.
        // End state tracking - removes state for views no longer in the tree.
        tuiContext.lifecycle.endRenderPass()
        tuiContext.stateStorage.endRenderPass()
    }

    /// Invalidates the diff cache, forcing a full repaint on the next render.
    ///
    /// Call this when the terminal is resized (SIGWINCH).
    func invalidateDiffCache() {
        diffWriter.invalidate()
    }

    // MARK: - Environment Assembly

    /// Builds a complete ``EnvironmentValues`` with all managed subsystems.
    ///
    /// Called once per render pass for the scene, and again for the status bar
    /// (which needs its own render context with different available height).
    ///
    /// - Returns: A fully populated environment.
    func buildEnvironment() -> EnvironmentValues {
        var environment = EnvironmentValues()
        environment.statusBar = statusBar
        environment.focusManager = focusManager
        environment.paletteManager = paletteManager
        if let palette = paletteManager.currentPalette {
            environment.palette = palette
        }
        environment.appearanceManager = appearanceManager
        if let appearance = appearanceManager.currentAppearance {
            environment.appearance = appearance
        }
        return environment
    }

    // MARK: - Private Helpers

    /// Renders a scene by delegating to ``SceneRenderable``.
    ///
    /// - Returns: The rendered ``FrameBuffer``, or an empty buffer if the
    ///   scene does not conform to ``SceneRenderable``.
    private func renderScene<S: Scene>(_ scene: S, context: RenderContext) -> FrameBuffer {
        if let renderable = scene as? SceneRenderable {
            return renderable.renderScene(context: context)
        }
        return FrameBuffer()
    }

    /// Renders the status bar at the specified terminal row.
    ///
    /// The status bar gets its own render context because its available
    /// height differs from the main content area. Output is diffed
    /// independently from the main content via ``FrameDiffWriter``.
    ///
    /// - Parameters:
    ///   - row: The 1-based terminal row where the status bar starts.
    ///   - terminalWidth: The current terminal width.
    ///   - bgCode: The ANSI background color code.
    ///   - reset: The ANSI reset code.
    private func renderStatusBar(
        atRow row: Int,
        terminalWidth: Int,
        bgCode: String,
        reset: String
    ) {
        // Build environment once for both palette resolution and render context
        let environment = buildEnvironment()
        let palette = environment.palette

        // Use palette colors for status bar (if not explicitly overridden)
        let highlightColor =
            statusBar.highlightColor == .cyan
            ? palette.accent
            : statusBar.highlightColor
        let labelColor = statusBar.labelColor ?? palette.foreground

        let statusBarView = StatusBar(
            userItems: statusBar.currentUserItems,
            systemItems: statusBar.currentSystemItems,
            style: statusBar.style,
            alignment: statusBar.alignment,
            highlightColor: highlightColor,
            labelColor: labelColor
        )

        let context = RenderContext(
            availableWidth: terminalWidth,
            availableHeight: statusBarView.height,
            environment: environment,
            tuiContext: tuiContext
        )

        let buffer = renderToBuffer(statusBarView, context: context)

        // Build terminal-ready output lines and write only changes
        let outputLines = diffWriter.buildOutputLines(
            buffer: buffer,
            terminalWidth: terminalWidth,
            terminalHeight: buffer.height,
            bgCode: bgCode,
            reset: reset
        )
        diffWriter.writeStatusBarDiff(
            newLines: outputLines,
            terminal: terminal,
            startRow: row
        )
    }
}
