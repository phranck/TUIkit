//
//  StatusBarItemsModifier.swift
//  SwiftTUI
//
//  A modifier that sets status bar items for a view.
//

import Foundation

// MARK: - StatusBarItemsModifier

/// A modifier that sets status bar items when a view is rendered.
///
/// This modifier allows views to declaratively specify their status bar items.
/// Items are pushed to the status bar context stack when the view renders
/// and can be automatically managed through the context system.
///
/// # Example
///
/// ```swift
/// struct MyView: TView {
///     var body: some TView {
///         VStack {
///             Text("Content")
///         }
///         .statusBarItems {
///             TStatusBarItem(shortcut: "n", label: "new") { addItem() }
///             TStatusBarItem(shortcut: Shortcut.escape, label: "back") { goBack() }
///         }
///     }
/// }
/// ```
public struct StatusBarItemsModifier<Content: TView>: TView {
    /// The content view.
    let content: Content

    /// The status bar items to display.
    let items: [any TStatusBarItemProtocol]

    /// Optional context identifier for this view's items.
    /// If nil, items are set as global items.
    let context: String?

    public var body: Never {
        fatalError("StatusBarItemsModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension StatusBarItemsModifier: Renderable {
    public func renderToBuffer(context renderContext: RenderContext) -> FrameBuffer {
        // Get the status bar from the environment
        let statusBar = renderContext.environment.statusBar

        // Set the items
        if let contextName = self.context {
            // Push items to a named context (useful for modals/dialogs)
            statusBar.push(context: contextName, items: items)
        } else {
            // Set as global items
            statusBar.setItems(items)
        }

        // Render the content
        return SwiftTUI.renderToBuffer(content, context: renderContext)
    }
}

// MARK: - TView Extension

extension TView {
    /// Sets the status bar items for this view.
    ///
    /// When this view is rendered, the specified items will be displayed
    /// in the status bar. This replaces any existing global items.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct MainView: TView {
    ///     var body: some TView {
    ///         VStack {
    ///             Text("Main Content")
    ///         }
    ///         .statusBarItems([
    ///             TStatusBarItem(shortcut: "q", label: "quit"),
    ///             TStatusBarItem(shortcut: "h", label: "help") { showHelp() }
    ///         ])
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter items: The status bar items to display.
    /// - Returns: A view that sets the specified status bar items.
    public func statusBarItems(_ items: [any TStatusBarItemProtocol]) -> some TView {
        StatusBarItemsModifier(content: self, items: items, context: nil)
    }

    /// Sets the status bar items for this view using a builder.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct MainView: TView {
    ///     var body: some TView {
    ///         VStack {
    ///             Text("Main Content")
    ///         }
    ///         .statusBarItems {
    ///             TStatusBarItem(shortcut: "q", label: "quit")
    ///             TStatusBarItem(shortcut: "h", label: "help") { showHelp() }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter builder: A closure that returns the status bar items.
    /// - Returns: A view that sets the specified status bar items.
    public func statusBarItems(
        @StatusBarItemBuilder _ builder: () -> [any TStatusBarItemProtocol]
    ) -> some TView {
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
    /// struct DialogView: TView {
    ///     var body: some TView {
    ///         Card {
    ///             Text("Are you sure?")
    ///         }
    ///         .statusBarItems(context: "confirm-dialog") {
    ///             TStatusBarItem(shortcut: "y", label: "yes") { confirm() }
    ///             TStatusBarItem(shortcut: "n", label: "no") { cancel() }
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
        @StatusBarItemBuilder _ builder: () -> [any TStatusBarItemProtocol]
    ) -> some TView {
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
        items: [any TStatusBarItemProtocol]
    ) -> some TView {
        StatusBarItemsModifier(content: self, items: items, context: context)
    }
}
