//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StatusBarState.swift
//
//  Created by LAYERED.work
//  License: MIT

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
/// // In renderToBuffer(context:):
/// let statusBar = context.environment.statusBar
/// statusBar.setItems([
///     StatusBarItem(shortcut: "⎋", label: "cancel")
/// ])
/// ```
public final class StatusBarState: @unchecked Sendable {
    // MARK: - Render Invalidation

    /// The app state used to trigger re-renders when status bar items change.
    private let appState: AppState

    // MARK: - User Items

    /// Stack of user contexts with their items (legacy push/pop API).
    private var userContextStack: [(context: String, items: [any StatusBarItemProtocol])] = []

    /// Global user items that are always shown (lowest priority).
    private var userGlobalItems: [any StatusBarItemProtocol] = []

    // MARK: - Section Items (Declarative API)

    /// Items registered per focus section during rendering.
    ///
    /// Each entry maps a section ID to its declared items and composition strategy.
    /// Rebuilt every render pass by ``StatusBarItemsModifier``.
    private var sectionItems: [(sectionID: String, items: [any StatusBarItemProtocol], composition: StatusBarItemComposition)] = []

    /// The focus manager used to determine the active section.
    ///
    /// Set by `RenderLoop` at the start of each render pass.
    weak var focusManager: FocusManager?

    /// The ID of the currently active focus section, read from the FocusManager.
    private var activeFocusSectionID: String? {
        focusManager?.activeSectionIdentifier
    }

    // MARK: - System Items Configuration

    /// Whether system items are shown at all.
    ///
    /// Set to `false` to hide all system items (quit, help, theme).
    /// Default is `true`.
    public var showSystemItems: Bool = true

    /// Whether the appearance item (`a`) is shown.
    ///
    /// When `true`, pressing `a` cycles through available appearances (border styles).
    /// Default is `false`.
    public var showAppearanceItem: Bool = false

    /// Whether the theme item (`t`) is shown.
    ///
    /// When `true`, pressing `t` cycles through available themes.
    /// Default is `false`.
    public var showThemeItem: Bool = false

    /// Controls when the quit shortcut is active.
    ///
    /// - `.always`: Quit works from any screen (default).
    /// - `.rootOnly`: Quit only works when no context is pushed (main screen).
    ///
    /// When set to `.rootOnly`, pressing the quit key on a subpage does nothing,
    /// allowing the app to handle navigation (e.g., go back) instead.
    public var quitBehavior: QuitBehavior = .always

    /// The keyboard shortcut used to quit the application.
    ///
    /// Defaults to `.q` (pressing `q` quits). Change this to use a different key:
    ///
    /// ```swift
    /// statusBar.quitShortcut = .escape   // ⎋ quit
    /// statusBar.quitShortcut = .ctrlQ    // ⌃q quit
    /// ```
    ///
    /// The status bar display updates automatically.
    public var quitShortcut: QuitShortcut = .q

    // MARK: - Appearance

    /// The current status bar style.
    public var style: StatusBarStyle = .bordered

    /// The horizontal alignment of items.
    public var alignment: StatusBarAlignment = .justified

    /// The highlight color for shortcut keys.
    public var highlightColor: Color = .cyan

    /// The label color.
    public var labelColor: Color?

    /// Creates a new status bar state.
    ///
    /// - Parameter appState: The app state instance for triggering re-renders.
    public init(appState: AppState) {
        self.appState = appState
    }

    /// Creates a status bar state with a default `AppState` instance.
    ///
    /// Used for environment key defaults and testing only.
    internal convenience init() {
        self.init(appState: AppState())
    }

    /// Whether we are at the root level (no context pushed).
    public var isAtRoot: Bool {
        userContextStack.isEmpty
    }

    /// Whether quit is currently allowed based on `quitBehavior`.
    public var isQuitAllowed: Bool {
        switch quitBehavior {
        case .always: return true
        case .rootOnly: return isAtRoot
        }
    }

    /// The current system items based on configuration flags.
    public var currentSystemItems: [StatusBarItem] {
        guard showSystemItems else { return [] }

        var items: [StatusBarItem] = []
        if isQuitAllowed {
            items.append(StatusBarItem(
                shortcut: quitShortcut.shortcutSymbol,
                label: quitShortcut.label,
                order: .quit
            ))
        }
        if showAppearanceItem { items.append(SystemStatusBarItem.appearance) }
        if showThemeItem { items.append(SystemStatusBarItem.theme) }
        return items
    }

    /// The current user items resolved from focus sections, context stack, or global items.
    public var currentUserItems: [any StatusBarItemProtocol] {
        if !sectionItems.isEmpty, let activeSectionID = activeFocusSectionID {
            return resolvedSectionItems(for: activeSectionID)
        }
        if let topContext = userContextStack.last { return topContext.items }
        return userGlobalItems
    }

    /// All currently active items for rendering and event handling.
    public var currentItems: [any StatusBarItemProtocol] {
        let userShortcuts = Set(currentUserItems.map { $0.shortcut })
        let filteredSystemItems = currentSystemItems.filter { !userShortcuts.contains($0.shortcut) }
        let sortedUserItems = currentUserItems.sorted { $0.order < $1.order }
        return sortedUserItems + filteredSystemItems
    }

    /// Whether the status bar has any items to display.
    public var hasItems: Bool { !currentItems.isEmpty }

    /// Whether there are any user items (ignoring system items).
    public var hasUserItems: Bool { !currentUserItems.isEmpty }

    /// The height of the status bar in lines.
    public var height: Int {
        guard hasItems else { return 0 }
        switch style {
        case .compact: return 1
        case .bordered: return 3
        }
    }
}

// MARK: - Public API

public extension StatusBarState {
    /// Sets the global user items. Triggers a re-render.
    func setItems(_ items: [any StatusBarItemProtocol]) {
        userGlobalItems = items
        appState.setNeedsRender()
    }

    /// Sets the global user items using a builder. Triggers a re-render.
    func setItems(@StatusBarItemBuilder _ builder: () -> [any StatusBarItemProtocol]) {
        userGlobalItems = builder()
        appState.setNeedsRender()
    }

    /// Pushes a new user context with its items onto the stack. Triggers a re-render.
    func push(context: String, items: [any StatusBarItemProtocol]) {
        userContextStack.removeAll { $0.context == context }
        userContextStack.append((context, items))
        appState.setNeedsRender()
    }

    /// Pushes a new user context using a builder. Triggers a re-render.
    func push(context: String, @StatusBarItemBuilder _ builder: () -> [any StatusBarItemProtocol]) {
        push(context: context, items: builder())
    }

    /// Pops a user context from the stack. Triggers a re-render.
    func pop(context: String) {
        userContextStack.removeAll { $0.context == context }
        appState.setNeedsRender()
    }

    /// Clears all user contexts (keeps global user items and system items). Triggers a re-render.
    func clearContexts() {
        userContextStack.removeAll()
        appState.setNeedsRender()
    }

    /// Clears all user items (global and contexts). System items remain.
    func clearUserItems() {
        userContextStack.removeAll()
        userGlobalItems.removeAll()
    }

    /// Clears everything including user items and hides system items.
    func clear() {
        userContextStack.removeAll()
        userGlobalItems.removeAll()
        showSystemItems = false
    }

    /// Handles a key event, checking if any current item matches.
    @discardableResult
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        for item in currentItems where item.matches(event) {
            if let statusBarItem = item as? StatusBarItem {
                if statusBarItem.hasAction {
                    statusBarItem.execute()
                    return true
                }
            }
        }
        return false
    }
}

// MARK: - Internal API

extension StatusBarState {
    /// Sets the global user items without triggering a re-render.
    func setItemsSilently(_ items: [any StatusBarItemProtocol]) {
        userGlobalItems = items
    }

    /// Registers status bar items for a focus section.
    func registerSectionItems(
        sectionID: String,
        items: [any StatusBarItemProtocol],
        composition: StatusBarItemComposition
    ) {
        sectionItems.removeAll { $0.sectionID == sectionID }
        sectionItems.append((sectionID, items, composition))
    }

    /// Clears all section items at the start of a render pass.
    func clearSectionItems() {
        sectionItems.removeAll()
    }

    /// Pushes a new user context without triggering a re-render.
    func pushSilently(context: String, items: [any StatusBarItemProtocol]) {
        userContextStack.removeAll { $0.context == context }
        userContextStack.append((context, items))
    }
}

// MARK: - Private Helpers

private extension StatusBarState {
    /// Resolves items for a given section using its composition strategy.
    func resolvedSectionItems(for sectionID: String) -> [any StatusBarItemProtocol] {
        guard let entry = sectionItems.first(where: { $0.sectionID == sectionID }) else {
            return userGlobalItems
        }

        switch entry.composition {
        case .replace:
            return entry.items
        case .merge:
            let sectionShortcuts = Set(entry.items.map { $0.shortcut })
            let filteredGlobal = userGlobalItems.filter { !sectionShortcuts.contains($0.shortcut) }
            return entry.items + filteredGlobal
        }
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
    /// let statusBar = context.environment.statusBar
    /// statusBar.setItems([
    ///     StatusBarItem(shortcut: "q", label: "quit")
    /// ])
    /// ```
    public var statusBar: StatusBarState {
        get { self[StatusBarKey.self] }
        set { self[StatusBarKey.self] = newValue }
    }
}
