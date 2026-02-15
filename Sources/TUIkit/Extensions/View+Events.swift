//  🖥️ TUIKit — Terminal UI Kit for Swift
//  View+Events.swift
//
//  Created by LAYERED.work
//  License: MIT

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
    public func onKeyPress(keys: Set<Key>, handler: @escaping (KeyEvent) -> Bool) -> some View {
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
    public func onKeyPress(_ key: Key, action: @escaping () -> Void) -> some View {
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

// MARK: - Value Change

extension View {
    /// Adds an action to perform when the given value changes.
    ///
    /// The action receives both the old and new values. Use this to react
    /// to state changes, for example to validate input or trigger side effects.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State var selection = 0
    ///
    ///     var body: some View {
    ///         List(selection: $selection) { ... }
    ///             .onChange(of: selection) { oldValue, newValue in
    ///                 loadDetails(for: newValue)
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - value: The value to observe for changes.
    ///   - initial: Whether to call the action on the first render pass.
    ///     When `true`, the action fires immediately with `oldValue == newValue`.
    ///     Defaults to `false`.
    ///   - action: The action to perform when the value changes, receiving
    ///     the old and new values.
    /// - Returns: A view that triggers an action on value changes.
    public func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        _ action: @escaping (V, V) -> Void
    ) -> some View {
        OnChangeModifier(content: self, value: value, initial: initial, action: action)
    }

    /// Adds an action to perform when the given value changes.
    ///
    /// This variant does not receive the old or new values. Use it when
    /// you only need to know that a change occurred.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Count: \(count)")
    ///     .onChange(of: count) {
    ///         playSound()
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - value: The value to observe for changes.
    ///   - initial: Whether to call the action on the first render pass.
    ///     Defaults to `false`.
    ///   - action: The action to perform when the value changes.
    /// - Returns: A view that triggers an action on value changes.
    public func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        _ action: @escaping () -> Void
    ) -> some View {
        OnChangeModifier(content: self, value: value, initial: initial) { _, _ in action() }
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
        StatusBarItemsModifier(content: self, items: items, composition: .merge, context: nil)
    }

    /// Declares status bar items for this view using a builder.
    ///
    /// When used inside a `.focusSection()`, items are composed with parent
    /// items using the `.merge` strategy (default). Use
    /// ``statusBarItems(_:_:)`` to specify a different strategy.
    ///
    /// # Example
    ///
    /// ```swift
    /// VStack {
    ///     Text("Main Content")
    /// }
    /// .statusBarItems {
    ///     StatusBarItem(shortcut: "q", label: "quit")
    ///     StatusBarItem(shortcut: "h", label: "help") { showHelp() }
    /// }
    /// ```
    ///
    /// - Parameter builder: A closure that returns the status bar items.
    /// - Returns: A view that declares the specified status bar items.
    public func statusBarItems(
        @StatusBarItemBuilder _ builder: () -> [any StatusBarItemProtocol]
    ) -> some View {
        StatusBarItemsModifier(content: self, items: builder(), composition: .merge, context: nil)
    }

    /// Declares status bar items with a specific composition strategy.
    ///
    /// - **`.merge`** (default): Items are combined with parent items.
    ///   Child wins on shortcut conflict.
    /// - **`.replace`**: Items replace all parent items (cascade barrier).
    ///
    /// # Example
    ///
    /// ```swift
    /// // Modal: replace all parent items
    /// SettingsView()
    ///     .focusSection("settings")
    ///     .statusBarItems(.replace) {
    ///         StatusBarItem(shortcut: Shortcut.escape, label: "close")
    ///         StatusBarItem(shortcut: Shortcut.enter, label: "confirm")
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - composition: How to compose with parent items.
    ///   - builder: A closure that returns the status bar items.
    /// - Returns: A view that declares the specified status bar items.
    public func statusBarItems(
        _ composition: StatusBarItemComposition,
        @StatusBarItemBuilder _ builder: () -> [any StatusBarItemProtocol]
    ) -> some View {
        StatusBarItemsModifier(content: self, items: builder(), composition: composition, context: nil)
    }

    /// Sets the status bar items for this view with a named context.
    ///
    /// This is the legacy push/pop API. Prefer using `.statusBarItems { ... }`
    /// with `.focusSection()` for declarative composition.
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - builder: A closure that returns the status bar items.
    /// - Returns: A view that pushes status bar items to the context stack.
    public func statusBarItems(
        context: String,
        @StatusBarItemBuilder _ builder: () -> [any StatusBarItemProtocol]
    ) -> some View {
        StatusBarItemsModifier(content: self, items: builder(), composition: .merge, context: context)
    }

    /// Sets the status bar items for this view with a named context.
    ///
    /// This is the legacy push/pop API. Prefer using `.statusBarItems()` with
    /// `.focusSection()` for declarative composition.
    ///
    /// - Parameters:
    ///   - context: A unique identifier for this context.
    ///   - items: The status bar items to display.
    /// - Returns: A view that pushes status bar items to the context stack.
    public func statusBarItems(
        context: String,
        items: [any StatusBarItemProtocol]
    ) -> some View {
        StatusBarItemsModifier(content: self, items: items, composition: .merge, context: context)
    }

    // MARK: - Focus Sections

    /// Declares this view as a focus section.
    ///
    /// A focus section is a named, focusable area of the UI. Interactive children
    /// (buttons, menus) within this section are grouped together. Users cycle
    /// between sections with Tab/Shift+Tab.
    ///
    /// Focus sections are **declarative** — they are registered during rendering,
    /// not added/removed imperatively. The `FocusManager` tracks which section
    /// is active and routes focus events accordingly.
    ///
    /// # Example
    ///
    /// ```swift
    /// HStack {
    ///     PlaylistView()
    ///         .focusSection("playlist")
    ///         .statusBarItems {
    ///             StatusBarItem(shortcut: Shortcut.enter, label: "play")
    ///         }
    ///
    ///     TrackListView()
    ///         .focusSection("tracklist")
    ///         .statusBarItems {
    ///             StatusBarItem(shortcut: Shortcut.enter, label: "select")
    ///         }
    /// }
    /// ```
    ///
    /// - Parameter id: A unique identifier for this section.
    /// - Returns: A view that registers a focus section during rendering.
    public func focusSection(_ id: String) -> some View {
        FocusSectionModifier(content: self, sectionID: id)
    }
}
