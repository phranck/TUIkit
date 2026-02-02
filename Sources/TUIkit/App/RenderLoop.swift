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
///   8. Diff against previous frame, write only changed lines
///   9. End lifecycle tracking (fires onDisappear for removed views)
///  10. Render status bar (with its own diff tracking)
/// ```
///
/// ## Diff-Based Rendering
///
/// `RenderLoop` uses a ``FrameDiffWriter`` to compare each frame's output
/// with the previous frame. Only lines that actually changed are written
/// to the terminal, reducing I/O by ~94% for mostly-static UIs.
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
    /// Each call:
    /// 1. Clears key event handlers and focus state
    /// 2. Begins lifecycle tracking
    /// 3. Renders the scene into a ``FrameBuffer``
    /// 4. Diffs against the previous frame and writes only changed lines
    /// 5. Ends lifecycle tracking (triggers `onDisappear` for removed views)
    /// 6. Renders the status bar at the bottom (with its own diff tracking)
    func render() {
        // Clear per-frame state before re-rendering
        tuiContext.keyEventDispatcher.clearHandlers()
        tuiContext.preferences.beginRenderPass()
        focusManager.clear()

        // Begin lifecycle and state tracking for this render pass
        tuiContext.lifecycle.beginRenderPass()
        tuiContext.stateStorage.beginRenderPass()

        // Calculate available height (reserve space for status bar)
        let statusBarHeight = statusBar.height
        let terminalWidth = terminal.width
        let terminalHeight = terminal.height
        let contentHeight = terminalHeight - statusBarHeight

        // Create render context with environment
        let environment = buildEnvironment()

        let context = RenderContext(
            terminal: terminal,
            availableWidth: terminalWidth,
            availableHeight: contentHeight,
            environment: environment,
            tuiContext: tuiContext
        )

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

        // Build terminal-ready output lines and write only changes
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
        diffWriter.writeContentDiff(
            newLines: outputLines,
            terminal: terminal,
            startRow: 1
        )

        // End lifecycle tracking - triggers onDisappear for removed views.
        // End state tracking - removes state for views no longer in the tree.
        tuiContext.lifecycle.endRenderPass()
        tuiContext.stateStorage.endRenderPass()

        // Render status bar separately (never dimmed, own diff tracking)
        if statusBar.hasItems {
            renderStatusBar(
                atRow: terminalHeight - statusBarHeight + 1,
                terminalWidth: terminalWidth,
                bgCode: bgCode,
                reset: reset
            )
        }
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
            terminal: terminal,
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
            terminalHeight: buffer.lines.count,
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
