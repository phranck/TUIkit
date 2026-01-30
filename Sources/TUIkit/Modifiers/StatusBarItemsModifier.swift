//
//  StatusBarItemsModifier.swift
//  TUIkit
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
/// struct MyView: View {
///     var body: some View {
///         VStack {
///             Text("Content")
///         }
///         .statusBarItems {
///             StatusBarItem(shortcut: "n", label: "new") { addItem() }
///             StatusBarItem(shortcut: Shortcut.escape, label: "back") { goBack() }
///         }
///     }
/// }
/// ```
public struct StatusBarItemsModifier<Content: View>: View {
    /// The content view.
    let content: Content

    /// The status bar items to display.
    let items: [any StatusBarItemProtocol]

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

        // Set the items silently (without triggering re-render) to avoid render loops.
        // The modifier is called during rendering, so we must not trigger another render.
        if let contextName = self.context {
            // Push items to a named context (useful for modals/dialogs)
            statusBar.pushSilently(context: contextName, items: items)
        } else {
            // Set as global items
            statusBar.setItemsSilently(items)
        }

        // Render the content
        return TUIkit.renderToBuffer(content, context: renderContext)
    }
}
