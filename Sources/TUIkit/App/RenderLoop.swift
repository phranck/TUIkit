//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderLoop.swift
//
//  Created by LAYERED.work
//  License: MIT  assembly, and status bar output.
//

// MARK: - Environment Snapshot

/// A snapshot of environment values that affect rendered output.
///
/// Used by `RenderLoop` to detect environment changes (theme, appearance)
/// between frames. When the snapshot differs from the previous frame, the
/// render cache is cleared so `EquatableView`-cached subtrees re-render
/// with the updated values.
///
/// Only tracks values that affect visual output — reference-type infrastructure
/// services (`FocusManager`, `ThemeManager`) are excluded.
private struct EnvironmentSnapshot: Equatable {
    /// The active palette identifier.
    let paletteID: String

    /// The active appearance identifier.
    let appearanceID: String

    /// Creates a snapshot from fully-built environment values.
    init(from environment: EnvironmentValues) {
        self.paletteID = environment.palette.id
        self.appearanceID = environment.appearance.id
    }
}

// MARK: - Render Loop

/// Manages the full rendering pipeline for each frame.
///
/// `RenderLoop` is owned by `AppRunner` and called once per frame.
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
/// `RenderLoop` uses a `FrameDiffWriter` to compare each frame's output
/// with the previous frame. Only lines that actually changed are written
/// to the terminal, reducing I/O by ~94% for mostly-static UIs.
///
/// ## Output Buffering
///
/// All diff writes (content + status bar) are collected in `Terminal`'s
/// frame buffer and flushed as a single `write()` syscall via
/// `Terminal.beginFrame()` / `Terminal.endFrame()`. This reduces
/// per-frame syscalls from ~40+ to exactly 1.
///
/// On terminal resize (SIGWINCH), the diff cache is invalidated to force
/// a full repaint.
///
/// ## Responsibilities
///
/// - Assembling ``EnvironmentValues`` from all subsystems
/// - Rendering the main scene content via `SceneRenderable`
/// - Rendering the status bar separately (never dimmed)
/// - Coordinating lifecycle tracking (appear/disappear)
/// - Diff-based terminal output via `FrameDiffWriter`
/// - Buffered frame output via `Terminal`
@MainActor
internal final class RenderLoop<A: App> {
    /// The user's app instance (provides `body`).
    let app: A

    /// The terminal for output and size queries.
    let terminal: Terminal

    /// The status bar state (height, items, appearance).
    let statusBar: StatusBarState

    /// The app header state (content buffer, visibility).
    let appHeader: AppHeaderState

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

    /// The environment snapshot from the previous frame.
    ///
    /// Compared after `buildEnvironment()` each frame. When the snapshot
    /// differs (e.g. palette or appearance changed), the render cache is
    /// cleared automatically. This ensures `EquatableView`-cached subtrees
    /// never serve stale content after theme changes — without requiring
    /// callers to manually invalidate the cache.
    private var lastEnvironmentSnapshot: EnvironmentSnapshot?

    /// Whether the first frame has been rendered.
    ///
    /// On the first frame, we perform a "measurement pass" to determine
    /// the actual header height before outputting anything. This prevents
    /// visible content jumping when the estimated header height differs
    /// from the actual height.
    private var isFirstFrame = true

    init(
        app: A,
        terminal: Terminal,
        statusBar: StatusBarState,
        appHeader: AppHeaderState,
        focusManager: FocusManager,
        paletteManager: ThemeManager,
        appearanceManager: ThemeManager,
        tuiContext: TUIContext
    ) {
        self.app = app
        self.terminal = terminal
        self.statusBar = statusBar
        self.appHeader = appHeader
        self.focusManager = focusManager
        self.paletteManager = paletteManager
        self.appearanceManager = appearanceManager
        self.tuiContext = tuiContext
    }
}

// MARK: - Internal API

extension RenderLoop {
    /// Performs a full render pass: scene content + status bar.
    ///
    /// See the class-level documentation for the complete pipeline steps.
    ///
    /// - Parameters:
    ///   - pulsePhase: The current breathing indicator phase (0–1).
    ///     Passed from `PulseTimer` via `AppRunner`.
    ///   - cursorTimer: The cursor timer for TextField/SecureField animations.
    func render(pulsePhase: Double = 0, cursorTimer: CursorTimer? = nil) {
        // Clear per-frame state before re-rendering
        tuiContext.keyEventDispatcher.clearHandlers()
        tuiContext.preferences.beginRenderPass()
        focusManager.beginRenderPass()
        statusBar.clearSectionItems()
        appHeader.beginRenderPass()

        // Provide the focus manager to the status bar for section resolution
        statusBar.focusManager = focusManager

        // Begin lifecycle, state, and cache tracking for this render pass
        tuiContext.lifecycle.beginRenderPass()
        tuiContext.stateStorage.beginRenderPass()
        tuiContext.renderCache.beginRenderPass()

        // Terminal size: single getSize() call avoids 2 ioctl syscalls per frame.
        let terminalSize = terminal.getSize()
        let statusBarHeight = statusBar.height
        let terminalWidth = terminalSize.width
        let terminalHeight = terminalSize.height

        // Create render context with environment
        var environment = buildEnvironment()
        environment.pulsePhase = pulsePhase
        environment.cursorTimer = cursorTimer
        invalidateCacheIfEnvironmentChanged(environment: environment)

        // Set up state hydration context BEFORE evaluating app.body so that
        // views constructed inside WindowGroup { ... } closures get persistent
        // state from the start.
        let rootIdentity = ViewIdentity(rootType: A.self)
        StateRegistration.activeContext = HydrationContext(
            identity: rootIdentity,
            storage: tuiContext.stateStorage
        )
        StateRegistration.counter = 0

        let scene = app.body

        StateRegistration.activeContext = nil
        tuiContext.stateStorage.markActive(rootIdentity)

        // Determine header height. On the first frame, we perform a measurement
        // pass to discover the actual header height before outputting anything.
        // This prevents visible content jumping.
        let appHeaderHeight: Int
        if isFirstFrame {
            // Measurement pass: render once to populate appHeader.contentBuffer
            let measureContext = RenderContext(
                availableWidth: terminalWidth,
                availableHeight: terminalHeight - statusBarHeight,
                environment: environment
            )
            _ = renderScene(scene, context: measureContext.withChildIdentity(type: type(of: scene)))
            appHeaderHeight = appHeader.height
            isFirstFrame = false
        } else {
            // Subsequent frames: use the estimate from the previous frame.
            // If it differs after rendering, we re-render with the correct height.
            appHeaderHeight = appHeader.estimatedHeight
        }

        let contentHeight = terminalHeight - statusBarHeight - appHeaderHeight

        var context = RenderContext(
            availableWidth: terminalWidth,
            availableHeight: contentHeight,
            environment: environment
        )
        context.hasExplicitWidth = true  // Terminal has a fixed width
        context.hasExplicitHeight = true  // Terminal has a fixed height

        // Render main content into a FrameBuffer.
        // app.body is evaluated fresh each frame. @State values survive
        // because State.init self-hydrates from StateStorage.
        var buffer = renderScene(scene, context: context.withChildIdentity(type: type(of: scene)))

        // Now the AppHeaderModifier has run and populated the header buffer.
        // Read the actual header height for correct positioning.
        let actualHeaderHeight = appHeader.height
        let actualContentHeight = terminalHeight - statusBarHeight - actualHeaderHeight

        // If the header height changed (e.g. header appeared, disappeared, or
        // changed line count), the content start row shifted. Re-render with
        // the correct height so centering is accurate.
        if actualHeaderHeight != appHeaderHeight {
            diffWriter.invalidate()

            // Re-render with correct content height for proper centering
            var correctedContext = RenderContext(
                availableWidth: terminalWidth,
                availableHeight: actualContentHeight,
                environment: environment
            )
            correctedContext.hasExplicitWidth = true
            correctedContext.hasExplicitHeight = true
            buffer = renderScene(scene, context: correctedContext.withChildIdentity(type: type(of: scene)))
        }

        // Validate focus state: if previously active section or focused element
        // is no longer in the tree, fall back to first available.
        focusManager.endRenderPass()

        // Use actual header height for content positioning (may differ from estimate)
        let finalHeaderHeight = appHeader.height
        let finalContentHeight = terminalHeight - statusBarHeight - finalHeaderHeight

        // Build terminal-ready output lines and write only changes.
        // All terminal writes between beginFrame/endFrame are collected
        // in an internal buffer and flushed as a single write() syscall.
        let bgColor = environment.palette.background
        let bgCode = ANSIRenderer.backgroundCode(for: bgColor)
        let reset = ANSIRenderer.reset

        let outputLines = diffWriter.buildOutputLines(
            buffer: buffer,
            terminalWidth: terminalWidth,
            terminalHeight: finalContentHeight,
            bgCode: bgCode,
            reset: reset
        )

        terminal.beginFrame()

        // Render app header at the top (if content was set by modifier)
        if appHeader.hasContent {
            renderAppHeader(
                atRow: 1,
                terminalWidth: terminalWidth,
                bgCode: bgCode,
                reset: reset
            )
        }

        // Render main content below the app header
        diffWriter.writeContentDiff(
            newLines: outputLines,
            terminal: terminal,
            startRow: 1 + finalHeaderHeight
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
        // End state/cache tracking - removes entries for views no longer in the tree.
        tuiContext.lifecycle.endRenderPass()
        tuiContext.stateStorage.endRenderPass()
        tuiContext.renderCache.removeInactive()
        tuiContext.renderCache.logFrameStats()
    }

    /// Invalidates the diff cache, forcing a full repaint on the next render.
    ///
    /// Call this when the terminal is resized (SIGWINCH).
    func invalidateDiffCache() {
        diffWriter.invalidate()
    }

    /// Builds a complete ``EnvironmentValues`` with all managed subsystems.
    ///
    /// - Returns: A fully populated environment.
    func buildEnvironment() -> EnvironmentValues {
        var environment = EnvironmentValues()
        environment.statusBar = statusBar
        environment.appHeader = appHeader
        environment.focusManager = focusManager
        environment.paletteManager = paletteManager
        if let palette = paletteManager.currentPalette {
            environment.palette = palette
        }
        environment.appearanceManager = appearanceManager
        if let appearance = appearanceManager.currentAppearance {
            environment.appearance = appearance
        }
        environment.notificationService = NotificationService.current

        // Runtime services (previously accessed via context.tuiContext)
        environment.stateStorage = tuiContext.stateStorage
        environment.lifecycle = tuiContext.lifecycle
        environment.keyEventDispatcher = tuiContext.keyEventDispatcher
        environment.renderCache = tuiContext.renderCache
        environment.preferenceStorage = tuiContext.preferences
        environment.renderNotifier = RenderNotifier.current

        return environment
    }
}

// MARK: - Private Helpers

private extension RenderLoop {
    /// Clears the render cache when environment values affecting visual output changed.
    ///
    /// Compares the current palette and appearance identifiers with the previous
    /// frame's snapshot. On mismatch, all `EquatableView`-cached subtrees are
    /// invalidated so they re-render with the new theme/appearance.
    ///
    /// This runs once per frame (two string comparisons) and ensures
    /// developers never need to manually invalidate the cache after theme changes.
    func invalidateCacheIfEnvironmentChanged(environment: EnvironmentValues) {
        let currentSnapshot = EnvironmentSnapshot(from: environment)
        if let lastSnapshot = lastEnvironmentSnapshot, lastSnapshot != currentSnapshot {
            tuiContext.renderCache.clearAll()
        }
        lastEnvironmentSnapshot = currentSnapshot
    }

    /// Renders a scene by delegating to `SceneRenderable`.
    func renderScene<S: Scene>(_ scene: S, context: RenderContext) -> FrameBuffer {
        if let renderable = scene as? SceneRenderable {
            return renderable.renderScene(context: context)
        }
        return FrameBuffer()
    }

    /// Renders the app header at the specified terminal row.
    func renderAppHeader(atRow row: Int, terminalWidth: Int, bgCode: String, reset: String) {
        guard let contentBuffer = appHeader.contentBuffer else { return }

        let environment = buildEnvironment()
        let headerView = AppHeader(contentBuffer: contentBuffer)

        let context = RenderContext(
            availableWidth: terminalWidth,
            availableHeight: appHeader.height,
            environment: environment
        )

        let buffer = renderToBuffer(headerView, context: context)

        let outputLines = diffWriter.buildOutputLines(
            buffer: buffer,
            terminalWidth: terminalWidth,
            terminalHeight: buffer.height,
            bgCode: bgCode,
            reset: reset
        )
        diffWriter.writeAppHeaderDiff(newLines: outputLines, terminal: terminal, startRow: row)
    }

    /// Renders the status bar at the specified terminal row.
    func renderStatusBar(atRow row: Int, terminalWidth: Int, bgCode: String, reset: String) {
        let environment = buildEnvironment()
        let palette = environment.palette

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
            environment: environment
        )

        let buffer = renderToBuffer(statusBarView, context: context)

        let outputLines = diffWriter.buildOutputLines(
            buffer: buffer,
            terminalWidth: terminalWidth,
            terminalHeight: buffer.height,
            bgCode: bgCode,
            reset: reset
        )
        diffWriter.writeStatusBarDiff(newLines: outputLines, terminal: terminal, startRow: row)
    }
}
