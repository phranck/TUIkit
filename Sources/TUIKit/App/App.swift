//
//  App.swift
//  TUIKit
//
//  The base protocol for TUIKit applications.
//

import Foundation

// MARK: - App Protocol

/// The base protocol for TUIKit applications.
///
/// `App` is the entry point for every TUIKit application,
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

// MARK: - Quit Behavior

/// Controls when the quit shortcut (`q`) is active.
public enum QuitBehavior: Sendable {
    /// Quit works from any screen.
    ///
    /// Pressing `q` will always exit the application, regardless of
    /// the current navigation state.
    case always

    /// Quit only works from the root/main screen.
    ///
    /// Pressing `q` will only exit when no context is pushed onto the
    /// status bar stack. On subpages, `q` does nothing, allowing the
    /// app to handle navigation (e.g., ESC to go back).
    case rootOnly
}

// MARK: - Status Bar State

/// Manages the status bar state for the running application.
///
/// This class is created by the `AppRunner` and injected into the
/// environment for views to access.
///
/// # Usage
///
/// ```swift
/// struct MyView: View {
///     @Environment(\.statusBar) var statusBar
///
///     var body: some View {
///         Button("Action") {
///             statusBar.setItems([
///                 StatusBarItem(shortcut: "⎋", label: "cancel")
///             ])
///         }
///     }
/// }
/// ```
public final class StatusBarState: @unchecked Sendable {
    // MARK: - User Items

    /// Stack of user contexts with their items.
    private var userContextStack: [(context: String, items: [any StatusBarItemProtocol])] = []

    /// Global user items that are always shown (lowest priority).
    private var userGlobalItems: [any StatusBarItemProtocol] = []

    // MARK: - System Items Configuration

    /// Whether system items are shown at all.
    ///
    /// Set to `false` to hide all system items (quit, help, theme).
    /// Default is `true`.
    public var showSystemItems: Bool = true

    /// Whether the appearance item (`a`) is shown.
    ///
    /// When `true`, pressing `a` cycles through available appearances (border styles).
    /// Default is `true`.
    public var showAppearanceItem: Bool = true

    /// Whether the theme item (`t`) is shown.
    ///
    /// When `true`, pressing `t` cycles through available themes.
    /// Default is `true`.
    public var showThemeItem: Bool = true

    /// Controls when the quit shortcut (`q`) is active.
    ///
    /// - `.always`: Quit works from any screen (default).
    /// - `.rootOnly`: Quit only works when no context is pushed (main screen).
    ///
    /// When set to `.rootOnly`, pressing `q` on a subpage does nothing,
    /// allowing the app to handle navigation (e.g., go back) instead.
    public var quitBehavior: QuitBehavior = .always

    // MARK: - Appearance

    /// The current status bar style.
    public var style: StatusBarStyle = .compact

    /// The horizontal alignment of items.
    public var alignment: StatusBarAlignment = .justified

    /// The highlight color for shortcut keys.
    public var highlightColor: Color = .cyan

    /// The label color.
    public var labelColor: Color?

    /// Creates a new status bar state.
    public init() {
        // System items are built dynamically based on flags
    }

    // MARK: - System Items Access

    /// Whether we are at the root level (no context pushed).
    public var isAtRoot: Bool {
        userContextStack.isEmpty
    }

    /// Whether quit is currently allowed based on `quitBehavior`.
    public var isQuitAllowed: Bool {
        switch quitBehavior {
        case .always:
            return true
        case .rootOnly:
            return isAtRoot
        }
    }

    /// The current system items based on configuration flags.
    ///
    /// Returns items filtered by `showSystemItems`, `showAppearanceItem`, `showThemeItem`,
    /// and `quitBehavior`. The quit item is only included when quit is allowed.
    public var currentSystemItems: [StatusBarItem] {
        guard showSystemItems else { return [] }

        var items: [StatusBarItem] = []

        // Quit item respects quitBehavior
        if isQuitAllowed {
            items.append(SystemStatusBarItem.quit)
        }

        if showAppearanceItem {
            items.append(SystemStatusBarItem.appearance)
        }

        if showThemeItem {
            items.append(SystemStatusBarItem.theme)
        }

        return items
    }

    // MARK: - User Items Management

    /// Sets the global user items.
    ///
    /// These items are shown when no context is active.
    /// System items are always shown in addition to these (unless disabled).
    /// Triggers a re-render.
    ///
    /// - Parameter items: The user items to display.
    public func setItems(_ items: [any StatusBarItemProtocol]) {
        userGlobalItems = items
        AppState.shared.setNeedsRender()
    }

    /// Sets the global user items using a builder.
    ///
    /// Triggers a re-render.
    ///
    /// - Parameter builder: A closure that returns items.
    public func setItems(@StatusBarItemBuilder _ builder: () -> [any StatusBarItemProtocol]) {
        userGlobalItems = builder()
        AppState.shared.setNeedsRender()
    }

    /// Sets the global user items without triggering a re-render.
    ///
    /// Use this during rendering (e.g., from modifiers) to avoid render loops.
    ///
    /// - Parameter items: The items to display.
    internal func setItemsSilently(_ items: [any StatusBarItemProtocol]) {
        userGlobalItems = items
    }

    /// The current user items (topmost context or global user items).
    ///
    /// Does not include system items.
    public var currentUserItems: [any StatusBarItemProtocol] {
        if let topContext = userContextStack.last {
            return topContext.items
        }
        return userGlobalItems
    }

    // MARK: - User Context Stack

    /// Pushes a new user context with its items onto the stack.
    ///
    /// Items from the most recent context are displayed instead of global user items.
    /// System items are always shown in addition to context items.
    /// Triggers a re-render.
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - items: The user items to display for this context.
    public func push(context: String, items: [any StatusBarItemProtocol]) {
        userContextStack.removeAll { $0.context == context }
        userContextStack.append((context, items))
        AppState.shared.setNeedsRender()
    }

    /// Pushes a new user context without triggering a re-render.
    ///
    /// Use this during rendering (e.g., from modifiers) to avoid render loops.
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - items: The items to display for this context.
    internal func pushSilently(context: String, items: [any StatusBarItemProtocol]) {
        userContextStack.removeAll { $0.context == context }
        userContextStack.append((context, items))
    }

    /// Pushes a new user context using a builder.
    ///
    /// Triggers a re-render.
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - builder: A closure that returns items.
    public func push(context: String, @StatusBarItemBuilder _ builder: () -> [any StatusBarItemProtocol]) {
        push(context: context, items: builder())
    }

    /// Pops a user context from the stack.
    ///
    /// Triggers a re-render.
    ///
    /// - Parameter context: The context identifier to remove.
    public func pop(context: String) {
        userContextStack.removeAll { $0.context == context }
        AppState.shared.setNeedsRender()
    }

    /// Clears all user contexts (keeps global user items and system items).
    ///
    /// Triggers a re-render.
    public func clearContexts() {
        userContextStack.removeAll()
        AppState.shared.setNeedsRender()
    }

    /// Clears all user items (global and contexts).
    ///
    /// System items remain visible unless `showSystemItems` is set to false.
    public func clearUserItems() {
        userContextStack.removeAll()
        userGlobalItems.removeAll()
    }

    /// Clears everything including user items and hides system items.
    ///
    /// After calling this, the status bar will be empty until new items are set
    /// or `showSystemItems` is set back to `true`.
    public func clear() {
        userContextStack.removeAll()
        userGlobalItems.removeAll()
        showSystemItems = false
    }

    // MARK: - Combined Items

    /// All currently active items for rendering and event handling.
    ///
    /// Layout: `[sorted user items] + [system items with fixed order]`
    ///
    /// If a user item has the same shortcut as a system item, the user item
    /// replaces the system item (user items take priority).
    public var currentItems: [any StatusBarItemProtocol] {
        // Get shortcuts used by user items (for deduplication)
        let userShortcuts = Set(currentUserItems.map { $0.shortcut })

        // Filter out system items that are overridden by user items
        let filteredSystemItems = currentSystemItems.filter { !userShortcuts.contains($0.shortcut) }

        // Sort user items by order, then append system items (fixed order)
        let sortedUserItems = currentUserItems.sorted { $0.order < $1.order }

        return sortedUserItems + filteredSystemItems
    }

    /// Whether the status bar has any items to display.
    public var hasItems: Bool {
        !currentItems.isEmpty
    }

    /// Whether there are any user items (ignoring system items).
    public var hasUserItems: Bool {
        !currentUserItems.isEmpty
    }

    /// The height of the status bar in lines.
    ///
    /// Returns 0 only if no items are present.
    public var height: Int {
        guard hasItems else { return 0 }
        switch style {
        case .compact: return 1
        case .bordered: return 3
        }
    }

    // MARK: - Event Handling

    /// Handles a key event, checking if any current item matches.
    ///
    /// Only returns true if the item has an action to execute.
    /// Items without actions (informational items) don't consume the event,
    /// allowing default handlers to process it.
    ///
    /// - Parameter event: The key event to handle.
    /// - Returns: True if an item with an action handled the event.
    @discardableResult
    public func handleKeyEvent(_ event: KeyEvent) -> Bool {
        for item in currentItems where item.matches(event) {
            if let statusBarItem = item as? StatusBarItem {
                // Only consume the event if the item has an action
                if statusBarItem.hasAction {
                    statusBarItem.execute()
                    return true
                }
            }
        }
        return false
    }
}

// MARK: - StatusBar Environment Key

/// Environment key for accessing the status bar state.
private struct StatusBarKey: EnvironmentKey {
    static let defaultValue = StatusBarState()
}

extension EnvironmentValues {
    /// The status bar state for the current application.
    ///
    /// Use this to set status bar items from within your views:
    ///
    /// ```swift
    /// @Environment(\.statusBar) var statusBar
    ///
    /// statusBar.setItems([
    ///     StatusBarItem(shortcut: "q", label: "quit")
    /// ])
    /// ```
    public var statusBar: StatusBarState {
        get { self[StatusBarKey.self] }
        set { self[StatusBarKey.self] = newValue }
    }
}

// MARK: - Signal Handler Flag

/// Flag set by the SIGWINCH signal handler to request a re-render.
///
/// Marked `nonisolated(unsafe)` because it is written from a signal handler
/// and read from the main loop. A single-word Bool write/read is practically
/// atomic on arm64/x86_64. Using `Atomic<Bool>` from the `Synchronization`
/// module would be cleaner but requires macOS 15+.
nonisolated(unsafe) private var needsRerender = false

/// Flag set by the SIGINT signal handler to request a graceful shutdown.
///
/// The actual cleanup (disabling raw mode, restoring cursor, exiting
/// alternate screen) happens in the main loop — signal handlers must
/// not call non-async-signal-safe functions like `write()` or `fflush()`.
nonisolated(unsafe) private var needsShutdown = false

// MARK: - App Runner

/// Runs an App.
internal final class AppRunner<A: App> {
    let app: A
    let terminal: Terminal
    let statusBar: StatusBarState
    let focusManager: FocusManager
    let paletteManager: ThemeManager
    let appearanceManager: ThemeManager
    private var isRunning = false

    init(app: A) {
        self.app = app
        self.terminal = Terminal.shared
        self.statusBar = StatusBarState()
        self.focusManager = FocusManager()
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
    }

    func run() {
        // Setup
        setupSignalHandlers()
        terminal.enterAlternateScreen()
        terminal.hideCursor()
        terminal.enableRawMode()

        // Set up environment with all managed subsystems
        EnvironmentStorage.shared.environment = buildEnvironment()

        // Register for state changes
        AppState.shared.observe {
            needsRerender = true
        }

        isRunning = true

        // Initial render
        render()

        // Main loop
        while isRunning {
            // Check for graceful shutdown request (from SIGINT handler)
            if needsShutdown {
                isRunning = false
                break
            }

            // Check if terminal was resized or state changed
            if needsRerender || AppState.shared.needsRender {
                needsRerender = false
                AppState.shared.didRender()
                render()
            }

            // Read key events
            if let keyEvent = terminal.readKeyEvent() {
                handleKeyEvent(keyEvent)
            }
        }

        // Cleanup
        cleanup()
    }

    private func render() {
        // Clear event handlers before re-rendering
        KeyEventDispatcher.shared.clearHandlers()
        focusManager.clear()

        // Begin lifecycle tracking for this render pass
        LifecycleTracker.shared.beginRenderPass()

        // Calculate available height (reserve space for status bar)
        let statusBarHeight = statusBar.height
        let contentHeight = terminal.height - statusBarHeight

        // Create render context with environment
        let environment = buildEnvironment()

        let context = RenderContext(
            terminal: terminal,
            availableWidth: terminal.width,
            availableHeight: contentHeight,
            environment: environment
        )

        // Update global environment storage
        EnvironmentStorage.shared.environment = environment

        // Render main content (background fill happens in renderScene)
        let scene = app.body
        renderScene(scene, context: context)

        // End lifecycle tracking - triggers onDisappear for removed views
        LifecycleTracker.shared.endRenderPass(onDisappear: DisappearCallbackStorage.shared.allCallbacks)

        // Render status bar separately (never dimmed)
        if statusBar.hasItems {
            renderStatusBar(atRow: terminal.height - statusBarHeight + 1)
        }
    }

    /// Builds a complete `EnvironmentValues` with all managed subsystems.
    ///
    /// Centralizes the environment setup that was previously duplicated
    /// in `run()`, `render()`, and `renderStatusBar()`.
    private func buildEnvironment() -> EnvironmentValues {
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

    private func renderScene<S: Scene>(_ scene: S, context: RenderContext) {
        if let renderable = scene as? SceneRenderable {
            renderable.renderScene(context: context)
        }
    }

    /// Renders the status bar at the specified row.
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
            environment: environment
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

    private func handleKeyEvent(_ event: KeyEvent) {
        // First, let the status bar handle the event
        if statusBar.handleKeyEvent(event) {
            return
        }

        // Then, let registered handlers try to handle the event
        if KeyEventDispatcher.shared.dispatch(event) {
            return
        }

        // Default handling (only if no handler consumed the event)
        switch event.key {
        case .character(let character) where character == "q" || character == "Q":
            // 'q' is the only way to quit (respects quitBehavior setting)
            if statusBar.isQuitAllowed {
                isRunning = false
            }

        case .character(let character) where character == "t" || character == "T":
            // 't' cycles palette (if theme item is enabled)
            if statusBar.showThemeItem {
                paletteManager.cycleNext()
            }

        case .character(let character) where character == "a" || character == "A":
            // 'a' cycles appearance
            appearanceManager.cycleNext()

        default:
            break
        }
    }

    private func cleanup() {
        terminal.disableRawMode()
        terminal.showCursor()
        terminal.exitAlternateScreen()
        AppState.shared.clearObservers()
        KeyEventDispatcher.shared.clearHandlers()
        EnvironmentStorage.shared.reset()
        focusManager.clear()
        LifecycleTracker.shared.reset()
        DisappearCallbackStorage.shared.reset()
        TaskStorage.shared.reset()
    }

    private func setupSignalHandlers() {
        // Catch SIGINT (Ctrl+C) — set a flag and let the main loop
        // handle cleanup. Signal handlers must only use async-signal-safe
        // operations; writing ANSI escapes or calling fflush() is NOT safe.
        signal(SIGINT) { _ in
            needsShutdown = true
        }

        // Catch SIGWINCH (terminal size change) — sets a flag
        // that the main loop picks up safely.
        signal(SIGWINCH) { _ in
            needsRerender = true
        }
    }
}

// MARK: - Scene Rendering Protocol

/// Internal protocol for renderable scenes.
internal protocol SceneRenderable {
    func renderScene(context: RenderContext)
}

extension WindowGroup: SceneRenderable {
    func renderScene(context: RenderContext) {
        let buffer = renderToBuffer(content, context: context)
        let terminal = Terminal.shared
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
