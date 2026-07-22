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

/// Per-subtree render-affecting environment values included in cache keys.
///
/// The subtree analog of ``EnvironmentSnapshot``'s global palette/appearance
/// clear: these values change a cached subtree's visual output without
/// changing its `Equatable` view value, so `EquatableView` snapshots them
/// per position and `RenderCache` misses on mismatch.
///
/// Members come from the issue #14 audit: `foregroundStyle` colors any text
/// below the wrapper; `focusIndicatorColor` drives the pulsing border
/// indicator inside an active focus section (pulse-derived, so entries
/// inside an active section refresh every tick instead of freezing).
/// Everything else read by renderables is either effect-bearing content
/// (bypassed by classification), globally snapshotted, or deliberately
/// excluded (`pulsePhase` itself).
private struct StyleEnvironmentFingerprint: Equatable, Sendable {
    /// The foreground color set via `.foregroundStyle(_:)`.
    let foregroundStyle: Color?

    /// The pulse-lerped focus indicator color of the enclosing section.
    let focusIndicatorColor: Color?

    /// Snapshots the fingerprint members from an environment.
    init(from environment: EnvironmentValues) {
        self.foregroundStyle = environment.foregroundStyle
        self.focusIndicatorColor = environment.focusIndicatorColor
    }
}

/// ANSI background codes for each render surface in a frame.
///
/// Keeping these grouped avoids accidentally rendering every surface
/// with `palette.background` and ignoring palette-specific tokens like
/// `statusBarBackground`.
internal struct RenderBackgroundCodes: Equatable {
    /// Main content area background code.
    let content: String

    /// App header background code.
    let appHeader: String

    /// Status bar background code.
    let statusBar: String

    init(palette: any Palette) {
        self.content = ANSIRenderer.backgroundCode(for: palette.background)
        self.appHeader = ANSIRenderer.backgroundCode(for: palette.appHeaderBackground)
        self.statusBar = ANSIRenderer.backgroundCode(for: palette.statusBarBackground)
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
///      @State values bind to persistent storage at final structural identities
///   6. Call SceneRenderable.renderScene() → FrameBuffer
///   7. Convert FrameBuffer to terminal-ready output lines
///   8. Begin buffered frame (terminal.beginFrame())
///   9. Diff against previous frame, write only changed lines to buffer
///  10. Render status bar into same buffer (with its own diff tracking)
///  11. Flush the entire frame (normally one write() syscall)
///  12. End lifecycle tracking (fires onDisappear for removed views)
/// ```
///
/// ## Render phases and per-pass collectors
///
/// A frame can traverse the view tree up to three times. Each traversal
/// carries a ``RenderPhase`` on its `RenderContext` and writes its
/// frame-scoped effects into fresh ``RenderPassCollectors``:
///
/// - **First-frame header sizing** runs in `.measure`: it only discovers the
///   app header height. Phase-guarded effect sites (lifecycle, task, focus
///   registration) stay inert, and the header buffer it renders lives in a
///   scratch collector that is dropped right after the height is read.
/// - **Main pass** and, when the header height changed, the **correction
///   pass** run in `.render` and produce the frame's candidate buffers.
///   A superseded main pass is discarded together with its collectors and
///   staged focus registrations.
/// - **Commit**: the FINAL pass's collectors are adopted into the live
///   managers (key handlers, preferences, status bar, header) and the
///   staged focus registrations are committed — the only point in a frame
///   where per-frame effect state reaches the live runtime.
///
/// Not yet guaranteed (tracked by issue #57): lifetime effects (`onAppear`,
/// `.task`, `onChange`, `onPreferenceChange` actions, GC liveness) still
/// apply during traversal instead of at the commit point. See
/// ``RenderPhase`` for the target model.
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
/// frame buffer and normally flushed as a single `write()` syscall via
/// `Terminal.beginFrame()` / `Terminal.endFrame()`. This reduces
/// per-frame syscalls from ~40+ to one unless the platform reports an
/// interruption or partial transfer that must be retried.
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
    let terminal: any TerminalProtocol

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
        terminal: any TerminalProtocol,
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
        beginRenderPass()

        // Terminal size: single getSize() call avoids 2 ioctl syscalls per frame.
        let terminalSize = terminal.getSize()
        let statusBarHeight = statusBar.height
        let terminalWidth = terminalSize.width
        let terminalHeight = terminalSize.height

        // Create render context with environment
        var environment = buildEnvironment()
        environment.pulsePhase = pulsePhase
        environment.cursorTimer = cursorTimer

        // Traversal window: main-thread invalidations from here until the
        // last pass finished are unsupported body side effects and get
        // diagnosed (see AppState.beginTraversal). Committed effect actions
        // replay after the window and stay legitimate.
        tuiContext.appState.beginTraversal()

        // Scene modifiers apply first (outside-in); a view-level root
        // palette (`.palette` inside the window content) still wins for
        // out-of-tree surfaces like the status bar and app header.
        let evaluatedScene = evaluateAppBody(environment: environment)
        let scene = SceneResolution.resolve(evaluatedScene, applyingTo: &environment)
        if let paletteOverrideScene = scene as? any RootPaletteOverrideProvidingScene,
           let paletteOverride = paletteOverrideScene.rootPaletteOverride() {
            environment.palette = paletteOverride
        }
        invalidateCacheIfEnvironmentChanged(environment: environment)

        // Determine header height. On the first frame, we perform a measurement
        // pass to discover the actual header height before outputting anything.
        // This prevents visible content jumping.
        let appHeaderHeight: Int
        if isFirstFrame {
            // This traversal only exists to size the app header — it runs in
            // the measure phase (guarded effect sites stay inert) and writes
            // into its own collectors, which are dropped right after the
            // height is read. Live state is never touched.
            let measureCollectors = RenderPassCollectors(appState: tuiContext.appState)
            var measureContext = RenderContext(
                availableWidth: terminalWidth,
                availableHeight: terminalHeight - statusBarHeight,
                environment: passEnvironment(environment, collectors: measureCollectors)
            )
            measureContext.phase = .measure
            focusManager.beginPass()
            _ = renderScene(scene, context: sceneContext(scene, base: measureContext))
            focusManager.discardPass()
            appHeaderHeight = measureCollectors.appHeader.height
            isFirstFrame = false
        } else {
            appHeaderHeight = appHeader.estimatedHeight
        }

        let contentHeight = terminalHeight - statusBarHeight - appHeaderHeight

        // Main pass: evaluate the frame's candidate tree into fresh
        // collectors. Nothing reaches live state until the commit below.
        var collectors = RenderPassCollectors(appState: tuiContext.appState)
        var context = RenderContext(
            availableWidth: terminalWidth,
            availableHeight: contentHeight,
            environment: passEnvironment(environment, collectors: collectors)
        )
        context.hasExplicitWidth = true
        context.hasExplicitHeight = true

        focusManager.beginPass()
        var buffer = renderScene(scene, context: sceneContext(scene, base: context))

        // If the header height changed after rendering, re-render with the
        // correct height so centering is accurate. The superseded main
        // pass's collectors and staged focus registrations are discarded;
        // the correction pass starts from clean scratch state.
        let actualHeaderHeight = collectors.appHeader.height
        if actualHeaderHeight != appHeaderHeight {
            diffWriter.invalidate()
            focusManager.discardPass()
            collectors = RenderPassCollectors(appState: tuiContext.appState)
            let actualContentHeight = terminalHeight - statusBarHeight - actualHeaderHeight
            var correctedContext = RenderContext(
                availableWidth: terminalWidth,
                availableHeight: actualContentHeight,
                environment: passEnvironment(environment, collectors: collectors)
            )
            correctedContext.hasExplicitWidth = true
            correctedContext.hasExplicitHeight = true
            focusManager.beginPass()
            buffer = renderScene(scene, context: sceneContext(scene, base: correctedContext))
        }

        tuiContext.appState.endTraversal()

        // COMMIT (step 6a): the single point where per-frame effect state
        // reaches the live runtime — the FINAL pass's collectors replace the
        // live managers' state, and the staged focus registrations are
        // committed with their deferred side effects.
        collectors.adoptIntoLiveManagers(of: tuiContext)
        focusManager.commitPass()

        writeFrame(
            buffer: buffer,
            environment: environment,
            terminalWidth: terminalWidth,
            terminalHeight: terminalHeight,
            statusBarHeight: statusBarHeight,
            headerHeight: appHeader.height
        )

        // COMMIT (step 6c): replay the final pass's lifetime effects
        // (onAppear, onDisappear registration, task mounts, deferred
        // actions) against the live managers — after terminal output, in
        // traversal order, exactly once. Records of discarded passes were
        // dropped with their collectors and never run.
        collectors.pendingEffects.commitDeferredEffects()

        // COMMIT (step 6d): GC on the committed tree only — the final
        // pass's liveness sets reach the managers, then endRenderPass
        // sweeps everything that only discarded passes touched.
        tuiContext.applyFrameLiveness(from: collectors.pendingEffects)
        endRenderPass()
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
        tuiContext.environmentValues()
    }

    /// Derives a per-pass environment that routes frame-scoped effect sinks
    /// into the pass's scratch collectors.
    ///
    /// Effect sites keep writing to `context.environment.keyEventDispatcher`
    /// and friends; only the instance behind those keys changes per pass.
    /// All other services (state storage, lifecycle, focus queries, palette,
    /// …) stay on the live runtime.
    ///
    /// The environment also carries the pass's effect-registration probe:
    /// a closure summing every effect sink of this pass, which
    /// `EquatableView` snapshots around a cache-miss rendering to decide
    /// whether the subtree is effect-free and safe to memoize.
    ///
    /// - Parameters:
    ///   - base: The frame's live environment.
    ///   - collectors: The scratch collectors of the current pass.
    /// - Returns: The environment to render this pass with.
    private func passEnvironment(
        _ base: EnvironmentValues,
        collectors: RenderPassCollectors
    ) -> EnvironmentValues {
        var environment = base
        environment.keyEventDispatcher = collectors.keyEventDispatcher
        environment.preferenceStorage = collectors.preferences
        environment.statusBar = collectors.statusBar
        environment.appHeader = collectors.appHeader
        environment.pendingFrameEffects = collectors.pendingEffects
        let keyEventDispatcher = collectors.keyEventDispatcher
        let preferences = collectors.preferences
        let statusBar = collectors.statusBar
        let pendingEffects = collectors.pendingEffects
        let focusManager = focusManager
        environment.effectRegistrationProbe = {
            keyEventDispatcher.handlerCount
                + preferences.writeCount
                + statusBar.passRegistrationCount
                + pendingEffects.deferredEffectCount
                + focusManager.stagedRegistrationCount
        }
        environment.environmentFingerprintProbe = { environment in
            EnvironmentFingerprint(StyleEnvironmentFingerprint(from: environment))
        }
        return environment
    }
}

// MARK: - Private Helpers

private extension RenderLoop {
    /// Clears all per-frame state and begins lifecycle/state/cache tracking.
    func beginRenderPass() {
        tuiContext.beginRenderPass()
    }

    /// Evaluates `App.body` with hydration and environment context active.
    ///
    /// Binds the app's dynamic properties to its root identity and makes the
    /// current environment available while evaluating `body`.
    func evaluateAppBody(environment: EnvironmentValues) -> A.Body {
        let rootIdentity = ViewIdentity(rootType: A.self)
        let context = RenderContext(
            availableWidth: 0,
            availableHeight: 0,
            environment: environment,
            identity: rootIdentity
        )

        let scene = StateRegistration.withHydration(of: app, context: context) {
            app.body
        }
        tuiContext.stateStorage.markActive(rootIdentity)

        return scene
    }

    /// Writes the assembled frame to the terminal using diff-based output.
    ///
    /// Builds terminal-ready output lines, then writes app header, content,
    /// and status bar inside a single buffered frame (normally one syscall).
    func writeFrame(
        buffer: FrameBuffer,
        environment: EnvironmentValues,
        terminalWidth: Int,
        terminalHeight: Int,
        statusBarHeight: Int,
        headerHeight: Int
    ) {
        let backgroundCodes = RenderBackgroundCodes(palette: environment.palette)
        let reset = ANSIRenderer.reset
        let contentHeight = terminalHeight - statusBarHeight - headerHeight

        let outputLines = diffWriter.buildOutputLines(
            buffer: buffer,
            terminalWidth: terminalWidth,
            terminalHeight: contentHeight,
            bgCode: backgroundCodes.content,
            reset: reset
        )

        terminal.beginFrame()

        if appHeader.hasContent {
            renderAppHeader(
                atRow: 1,
                terminalWidth: terminalWidth,
                environment: environment,
                bgCode: backgroundCodes.appHeader,
                reset: reset
            )
        }

        diffWriter.writeContentDiff(
            newLines: outputLines,
            terminal: terminal,
            startRow: 1 + headerHeight
        )

        if statusBar.hasItems {
            renderStatusBar(
                atRow: terminalHeight - statusBarHeight + 1,
                terminalWidth: terminalWidth,
                environment: environment,
                bgCode: backgroundCodes.statusBar,
                reset: reset
            )
        }

        terminal.endFrame()
    }

    /// Ends lifecycle, state, and cache tracking for this render pass.
    ///
    /// Fires `onDisappear` for removed views and removes state/cache
    /// entries for views no longer in the tree.
    func endRenderPass() {
        tuiContext.endRenderPass()
    }

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

    /// Renders a resolved scene core.
    func renderScene(_ scene: (any SceneRenderable)?, context: RenderContext) -> FrameBuffer {
        scene?.renderScene(context: context) ?? FrameBuffer()
    }

    /// Extends the identity path with the resolved scene's concrete type.
    ///
    /// Opening the existential keeps identity paths byte-identical to the
    /// pre-modifier era for unwrapped scenes (e.g. `WindowGroup<Content>`).
    func sceneContext(_ scene: (any SceneRenderable)?, base: RenderContext) -> RenderContext {
        guard let scene else { return base }
        return openedSceneContext(scene, base: base)
    }

    /// Opens the scene existential so the child identity uses its dynamic type.
    private func openedSceneContext<S: SceneRenderable>(_ scene: S, base: RenderContext) -> RenderContext {
        base.withChildIdentity(type: S.self)
    }

    /// Renders the app header at the specified terminal row.
    func renderAppHeader(
        atRow row: Int,
        terminalWidth: Int,
        environment: EnvironmentValues,
        bgCode: String,
        reset: String
    ) {
        guard let contentBuffer = appHeader.contentBuffer else { return }

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
    func renderStatusBar(
        atRow row: Int,
        terminalWidth: Int,
        environment: EnvironmentValues,
        bgCode: String,
        reset: String
    ) {
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
