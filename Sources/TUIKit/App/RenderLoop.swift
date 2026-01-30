//
//  RenderLoop.swift
//  TUIKit
//
//  Manages the rendering pipeline: scene rendering, environment
//  assembly, and status bar output.
//

// MARK: - Render Loop

/// Manages the full rendering pipeline for each frame.
///
/// Responsibilities:
/// - Assembling the ``EnvironmentValues`` from all subsystems
/// - Rendering the main scene content
/// - Rendering the status bar separately (never dimmed)
/// - Coordinating lifecycle tracking (appear/disappear)
///
/// `RenderLoop` is owned by ``AppRunner`` and called once per frame.
internal struct RenderLoop<A: App> {
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

    // MARK: - Rendering

    /// Performs a full render pass: scene content + status bar.
    ///
    /// Each call:
    /// 1. Clears key event handlers and focus state
    /// 2. Begins lifecycle tracking
    /// 3. Renders the scene into the terminal
    /// 4. Ends lifecycle tracking (triggers `onDisappear` for removed views)
    /// 5. Renders the status bar at the bottom
    func render() {
        // Clear per-frame state before re-rendering
        tuiContext.keyEventDispatcher.clearHandlers()
        tuiContext.preferences.beginRenderPass()
        focusManager.clear()

        // Begin lifecycle tracking for this render pass
        tuiContext.lifecycle.beginRenderPass()

        // Calculate available height (reserve space for status bar)
        let statusBarHeight = statusBar.height
        let contentHeight = terminal.height - statusBarHeight

        // Create render context with environment
        let environment = buildEnvironment()

        let context = RenderContext(
            terminal: terminal,
            availableWidth: terminal.width,
            availableHeight: contentHeight,
            environment: environment,
            tuiContext: tuiContext
        )

        // Update global environment storage
        EnvironmentStorage.shared.environment = environment

        // Render main content (background fill happens in renderScene)
        let scene = app.body
        renderScene(scene, context: context)

        // End lifecycle tracking - triggers onDisappear for removed views
        tuiContext.lifecycle.endRenderPass()

        // Render status bar separately (never dimmed)
        if statusBar.hasItems {
            renderStatusBar(atRow: terminal.height - statusBarHeight + 1)
        }
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
    private func renderScene<S: Scene>(_ scene: S, context: RenderContext) {
        if let renderable = scene as? SceneRenderable {
            renderable.renderScene(context: context)
        }
    }

    /// Renders the status bar at the specified terminal row.
    ///
    /// The status bar gets its own render context because its available
    /// height differs from the main content area. Theme background is
    /// applied line-by-line with ANSI code injection.
    private func renderStatusBar(atRow row: Int) {
        // Use theme colors for status bar (if not explicitly overridden)
        let highlightColor =
            statusBar.highlightColor == .cyan
            ? Color.theme.statusBarHighlight
            : statusBar.highlightColor
        let labelColor = statusBar.labelColor ?? Color.theme.statusBarForeground

        let statusBarView = StatusBar(
            userItems: statusBar.currentUserItems,
            systemItems: statusBar.currentSystemItems,
            style: statusBar.style,
            alignment: statusBar.alignment,
            highlightColor: highlightColor,
            labelColor: labelColor
        )

        // Create render context with current environment for palette colors
        let environment = buildEnvironment()

        let context = RenderContext(
            terminal: terminal,
            availableWidth: terminal.width,
            availableHeight: statusBarView.height,
            environment: environment,
            tuiContext: tuiContext
        )

        let buffer = renderToBuffer(statusBarView, context: context)

        // Get background color from palette
        let bgColor = paletteManager.currentPalette?.background ?? .black
        let bgCode = ANSIRenderer.backgroundCode(for: bgColor)
        let reset = ANSIRenderer.reset
        let terminalWidth = terminal.width

        // Write status bar with theme background
        for (index, line) in buffer.lines.enumerated() {
            terminal.moveCursor(toRow: row + index, column: 1)

            let visibleWidth = line.strippedLength
            let padding = max(0, terminalWidth - visibleWidth)

            // Replace all reset codes with "reset + restore background"
            let lineWithBg = line.replacingOccurrences(of: reset, with: reset + bgCode)
            let paddedLine = bgCode + lineWithBg + String(repeating: " ", count: padding) + reset
            terminal.write(paddedLine)
        }
    }
}
