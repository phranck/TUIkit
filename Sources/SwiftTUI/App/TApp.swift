//
//  TApp.swift
//  SwiftTUI
//
//  The base protocol for SwiftTUI applications.
//

import Foundation

// MARK: - TApp Protocol

/// The base protocol for SwiftTUI applications.
///
/// `TApp` is the entry point for every SwiftTUI application,
/// similar to `App` in SwiftUI.
///
/// # Example
///
/// ```swift
/// @main
/// struct MyApp: TApp {
///     var body: some TScene {
///         WindowGroup {
///             ContentView()
///         }
///     }
/// }
/// ```
public protocol TApp {
    /// The type of the main scene.
    associatedtype Body: TScene

    /// The main scene of the app.
    @SceneBuilder
    var body: Body { get }

    /// Initializes the app.
    init()
}

extension TApp {
    /// Starts the app.
    ///
    /// This method is called by the `@main` attribute and starts
    /// the main run loop of the application.
    public static func main() {
        let app = Self()
        let runner = AppRunner(app: app)
        runner.run()
    }
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
/// struct MyView: TView {
///     @Environment(\.statusBar) var statusBar
///
///     var body: some TView {
///         Button("Action") {
///             statusBar.setItems([
///                 TStatusBarItem(shortcut: "⎋", label: "cancel")
///             ])
///         }
///     }
/// }
/// ```
public final class StatusBarState: @unchecked Sendable {
    /// Stack of contexts with their items.
    private var contextStack: [(context: String, items: [any TStatusBarItemProtocol])] = []

    /// Global items that are always shown (lowest priority).
    private var globalItems: [any TStatusBarItemProtocol] = []

    /// The current status bar style.
    public var style: TStatusBarStyle = .compact

    /// The horizontal alignment of items.
    public var alignment: TStatusBarAlignment = .justified

    /// The highlight color for shortcut keys.
    public var highlightColor: Color = .cyan

    /// The label color.
    public var labelColor: Color? = nil

    /// Creates a new status bar state.
    public init() {}

    // MARK: - Items Management

    /// Sets the global status bar items.
    ///
    /// These items are shown when no context is active.
    /// Triggers a re-render.
    ///
    /// - Parameter items: The items to display.
    public func setItems(_ items: [any TStatusBarItemProtocol]) {
        globalItems = items
        AppState.shared.setNeedsRender()
    }

    /// Sets the global status bar items using a builder.
    ///
    /// Triggers a re-render.
    ///
    /// - Parameter builder: A closure that returns items.
    public func setItems(@StatusBarItemBuilder _ builder: () -> [any TStatusBarItemProtocol]) {
        globalItems = builder()
        AppState.shared.setNeedsRender()
    }

    /// Sets the global status bar items without triggering a re-render.
    ///
    /// Use this during rendering (e.g., from modifiers) to avoid render loops.
    ///
    /// - Parameter items: The items to display.
    internal func setItemsSilently(_ items: [any TStatusBarItemProtocol]) {
        globalItems = items
    }

    // MARK: - Context Stack

    /// Pushes a new context with its items onto the stack.
    ///
    /// Items from the most recent context are displayed, hiding global items.
    /// Triggers a re-render.
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - items: The items to display for this context.
    public func push(context: String, items: [any TStatusBarItemProtocol]) {
        contextStack.removeAll { $0.context == context }
        contextStack.append((context, items))
        AppState.shared.setNeedsRender()
    }

    /// Pushes a new context without triggering a re-render.
    ///
    /// Use this during rendering (e.g., from modifiers) to avoid render loops.
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - items: The items to display for this context.
    internal func pushSilently(context: String, items: [any TStatusBarItemProtocol]) {
        contextStack.removeAll { $0.context == context }
        contextStack.append((context, items))
    }

    /// Pushes a new context using a builder.
    ///
    /// Triggers a re-render.
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - builder: A closure that returns items.
    public func push(context: String, @StatusBarItemBuilder _ builder: () -> [any TStatusBarItemProtocol]) {
        push(context: context, items: builder())
    }

    /// Pops a context from the stack.
    ///
    /// Triggers a re-render.
    ///
    /// - Parameter context: The context identifier to remove.
    public func pop(context: String) {
        contextStack.removeAll { $0.context == context }
        AppState.shared.setNeedsRender()
    }

    /// Clears all contexts (keeps global items).
    ///
    /// Triggers a re-render.
    public func clearContexts() {
        contextStack.removeAll()
        AppState.shared.setNeedsRender()
    }

    /// Clears everything including global items.
    public func clear() {
        contextStack.removeAll()
        globalItems.removeAll()
    }

    // MARK: - Current State

    /// The currently active items (topmost context or global).
    public var currentItems: [any TStatusBarItemProtocol] {
        if let topContext = contextStack.last {
            return topContext.items
        }
        return globalItems
    }

    /// Whether the status bar has any items to display.
    public var hasItems: Bool {
        !currentItems.isEmpty
    }

    /// The height of the status bar in lines.
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
        for item in currentItems {
            if item.matches(event) {
                if let statusBarItem = item as? TStatusBarItem {
                    // Only consume the event if the item has an action
                    if statusBarItem.hasAction {
                        statusBarItem.execute()
                        return true
                    }
                }
            }
        }
        return false
    }
}

// MARK: - StatusBar Environment Key

/// Environment key for accessing the status bar state.
private struct StatusBarKey: EnvironmentKey {
    static let defaultValue: StatusBarState = StatusBarState()
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
    ///     TStatusBarItem(shortcut: "q", label: "quit")
    /// ])
    /// ```
    public var statusBar: StatusBarState {
        get { self[StatusBarKey.self] }
        set { self[StatusBarKey.self] = newValue }
    }
}

// MARK: - Signal Handler Flag

/// Flag set by the SIGWINCH signal handler to request a re-render.
/// Must be an atomic type safe for signal context.
private nonisolated(unsafe) var needsRerender = false

// MARK: - App Runner

/// Runs a TApp.
internal final class AppRunner<App: TApp> {
    let app: App
    let terminal: Terminal
    let statusBar: StatusBarState
    private var isRunning = false

    init(app: App) {
        self.app = app
        self.terminal = Terminal.shared
        self.statusBar = StatusBarState()
    }

    func run() {
        // Setup
        setupSignalHandlers()
        terminal.enterAlternateScreen()
        terminal.hideCursor()
        terminal.enableRawMode()

        // Set up environment with status bar
        var environment = EnvironmentValues()
        environment.statusBar = statusBar
        EnvironmentStorage.shared.environment = environment

        // Register for state changes
        AppState.shared.observe { [weak self] in
            needsRerender = true
            _ = self  // Silence warning
        }

        isRunning = true

        // Initial render
        render()

        // Main loop
        while isRunning {
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
        terminal.clear()

        // Clear event handlers before re-rendering
        KeyEventDispatcher.shared.clearHandlers()
        FocusManager.shared.clear()

        // Begin lifecycle tracking for this render pass
        LifecycleTracker.shared.beginRenderPass()

        // Calculate available height (reserve space for status bar)
        let statusBarHeight = statusBar.height
        let contentHeight = terminal.height - statusBarHeight

        // Create render context with environment
        var environment = EnvironmentValues()
        environment.statusBar = statusBar

        let context = RenderContext(
            terminal: terminal,
            availableWidth: terminal.width,
            availableHeight: contentHeight,
            environment: environment
        )

        // Update global environment storage
        EnvironmentStorage.shared.environment = environment

        // Render main content
        let scene = app.body
        renderScene(scene, context: context)

        // End lifecycle tracking - triggers onDisappear for removed views
        LifecycleTracker.shared.endRenderPass(onDisappear: DisappearCallbackStorage.shared.allCallbacks)

        // Render status bar separately (never dimmed)
        if statusBar.hasItems {
            renderStatusBar(atRow: terminal.height - statusBarHeight + 1)
        }
    }

    private func renderScene<S: TScene>(_ scene: S, context: RenderContext) {
        if let renderable = scene as? SceneRenderable {
            renderable.renderScene(context: context)
        }
    }

    /// Renders the status bar at the specified row.
    private func renderStatusBar(atRow row: Int) {
        let statusBarView = TStatusBar(
            items: statusBar.currentItems,
            style: statusBar.style,
            alignment: statusBar.alignment,
            highlightColor: statusBar.highlightColor,
            labelColor: statusBar.labelColor
        )
        let context = RenderContext(
            terminal: terminal,
            availableWidth: terminal.width,
            availableHeight: statusBarView.height
        )

        let buffer = renderToBuffer(statusBarView, context: context)

        // Write directly to terminal at the bottom
        for (index, line) in buffer.lines.enumerated() {
            terminal.moveCursor(toRow: row + index, column: 1)
            terminal.write(line)
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

        // Default handling (only if no handler consumed the event):
        // - ESC exits the app
        // - 'q' or 'Q' exits the app
        switch event.key {
        case .escape:
            isRunning = false
        case .character(let char) where char == "q" || char == "Q":
            isRunning = false
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
        FocusManager.shared.clear()
        LifecycleTracker.shared.reset()
        DisappearCallbackStorage.shared.reset()
        TaskStorage.shared.reset()
    }

    private func setupSignalHandlers() {
        // Catch SIGINT (Ctrl+C)
        signal(SIGINT) { _ in
            Terminal.shared.disableRawMode()
            Terminal.shared.showCursor()
            Terminal.shared.exitAlternateScreen()
            exit(0)
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
        // Write buffer to terminal
        let terminal = Terminal.shared
        for (index, line) in buffer.lines.enumerated() {
            terminal.moveCursor(toRow: 1 + index, column: 1)
            terminal.write(line)
        }
    }
}
