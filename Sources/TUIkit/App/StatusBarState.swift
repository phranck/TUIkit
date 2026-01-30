//
//  StatusBarState.swift
//  TUIkit
//
//  Manages the status bar state for the running application.
//

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
