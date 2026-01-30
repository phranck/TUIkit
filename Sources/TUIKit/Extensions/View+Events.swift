//
//  View+Events.swift
//  TUIKit
//
//  Event handling and lifecycle view modifiers: onKeyPress, onAppear, onDisappear, task, statusBarItems.
//

import Foundation

// MARK: - Key Press

extension View {
    /// Adds a handler for key press events.
    ///
    /// The handler is called when any key is pressed while this view
    /// is in the view hierarchy. Return `true` to consume the event,
    /// or `false` to let it propagate to other handlers.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Press any key")
    ///     .onKeyPress { event in
    ///         if event.key == .enter {
    ///             doSomething()
    ///             return true  // Consumed
    ///         }
    ///         return false  // Let others handle it
    ///     }
    /// ```
    ///
    /// - Parameter handler: The handler to call on key press. Returns true if handled.
    /// - Returns: A view that handles key presses.
    public func onKeyPress(_ handler: @escaping (KeyEvent) -> Bool) -> some View {
        KeyPressModifier(content: self, keys: nil, handler: handler)
    }

    /// Adds a handler for specific key press events.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Use arrow keys")
    ///     .onKeyPress(keys: [.up, .down]) { event in
    ///         if event.key == .up {
    ///             moveUp()
    ///         } else {
    ///             moveDown()
    ///         }
    ///         return true
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - keys: The keys to listen for.
    ///   - handler: The handler to call on key press. Returns true if handled.
    /// - Returns: A view that handles specific key presses.
    public func onKeyPress(keys: Set<Key>, handler: @escaping (KeyEvent) -> Bool) -> KeyPressModifier<Self> {
        KeyPressModifier(content: self, keys: keys, handler: handler)
    }

    /// Adds a handler for a single key press.
    ///
    /// This handler always consumes the event when the specified key is pressed.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Press Enter to continue")
    ///     .onKeyPress(.enter) {
    ///         continueAction()
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - key: The key to listen for.
    ///   - action: The action to perform.
    /// - Returns: A view that handles the specific key press.
    public func onKeyPress(_ key: Key, action: @escaping () -> Void) -> KeyPressModifier<Self> {
        KeyPressModifier(
            content: self,
            keys: [key],
            handler: { _ in
                action()
                return true
            }
        )
    }
}

// MARK: - Lifecycle

extension View {
    /// Executes an action when this view first appears.
    ///
    /// The action is only executed once per view appearance. If the view
    /// is removed and then added again, the action will execute again.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("Hello")
    ///             .onAppear {
    ///                 loadData()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter action: The action to execute.
    /// - Returns: A view that executes the action on appearance.
    public func onAppear(perform action: @escaping () -> Void) -> some View {
        OnAppearModifier(
            content: self,
            token: UUID().uuidString,
            action: action
        )
    }

    /// Executes an action when this view disappears.
    ///
    /// The action is executed when the view is no longer rendered.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("Hello")
    ///             .onDisappear {
    ///                 cleanup()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter action: The action to execute.
    /// - Returns: A view that executes the action on disappearance.
    public func onDisappear(perform action: @escaping () -> Void) -> some View {
        OnDisappearModifier(
            content: self,
            token: UUID().uuidString,
            action: action
        )
    }

    /// Starts an async task when this view appears.
    ///
    /// The task is automatically cancelled when the view disappears.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("Loading...")
    ///             .task {
    ///                 await fetchData()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - priority: The task priority (default: .userInitiated).
    ///   - action: The async action to execute.
    /// - Returns: A view that starts the task on appearance.
    public func task(
        priority: TaskPriority = .userInitiated,
        _ action: @escaping @Sendable () async -> Void
    ) -> some View {
        TaskModifier(
            content: self,
            token: UUID().uuidString,
            task: action,
            priority: priority
        )
    }
}

// MARK: - Status Bar Items

extension View {
    /// Sets the status bar items for this view.
    ///
    /// When this view is rendered, the specified items will be displayed
    /// in the status bar. This replaces any existing global items.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct MainView: View {
    ///     var body: some View {
    ///         VStack {
    ///             Text("Main Content")
    ///         }
    ///         .statusBarItems([
    ///             StatusBarItem(shortcut: "q", label: "quit"),
    ///             StatusBarItem(shortcut: "h", label: "help") { showHelp() }
    ///         ])
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter items: The status bar items to display.
    /// - Returns: A view that sets the specified status bar items.
    public func statusBarItems(_ items: [any StatusBarItemProtocol]) -> some View {
        StatusBarItemsModifier(content: self, items: items, context: nil)
    }

    /// Sets the status bar items for this view using a builder.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct MainView: View {
    ///     var body: some View {
    ///         VStack {
    ///             Text("Main Content")
    ///         }
    ///         .statusBarItems {
    ///             StatusBarItem(shortcut: "q", label: "quit")
    ///             StatusBarItem(shortcut: "h", label: "help") { showHelp() }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter builder: A closure that returns the status bar items.
    /// - Returns: A view that sets the specified status bar items.
    public func statusBarItems(
        @StatusBarItemBuilder _ builder: () -> [any StatusBarItemProtocol]
    ) -> some View {
        StatusBarItemsModifier(content: self, items: builder(), context: nil)
    }

    /// Sets the status bar items for this view with a named context.
    ///
    /// Items are pushed to the context stack, allowing nested views
    /// (like dialogs) to temporarily override the status bar items.
    /// Use `pop(context:)` to restore the previous items.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct DialogView: View {
    ///     var body: some View {
    ///         Card {
    ///             Text("Are you sure?")
    ///         }
    ///         .statusBarItems(context: "confirm-dialog") {
    ///             StatusBarItem(shortcut: "y", label: "yes") { confirm() }
    ///             StatusBarItem(shortcut: "n", label: "no") { cancel() }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - builder: A closure that returns the status bar items.
    /// - Returns: A view that pushes status bar items to the context stack.
    public func statusBarItems(
        context: String,
        @StatusBarItemBuilder _ builder: () -> [any StatusBarItemProtocol]
    ) -> some View {
        StatusBarItemsModifier(content: self, items: builder(), context: context)
    }

    /// Sets the status bar items for this view with a named context.
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - items: The status bar items to display.
    /// - Returns: A view that pushes status bar items to the context stack.
    public func statusBarItems(
        context: String,
        items: [any StatusBarItemProtocol]
    ) -> some View {
        StatusBarItemsModifier(content: self, items: items, context: context)
    }
}
