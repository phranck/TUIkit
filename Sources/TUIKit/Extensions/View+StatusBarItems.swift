//
//  View+StatusBarItems.swift
//  TUIKit
//
//  The .statusBarItems() view extensions for setting status bar items.
//

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
