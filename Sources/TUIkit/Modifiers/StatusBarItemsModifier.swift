//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StatusBarItemsModifier.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

import Foundation

// MARK: - StatusBarItemsModifier

/// A modifier that declares status bar items for a view.
///
/// Items are registered with the ``StatusBarState`` during rendering.
/// When used together with ``FocusSectionModifier``, the composition
/// strategy determines how items relate to parent items:
///
/// - **`.merge`** (default): Items are combined with parent items.
/// - **`.replace`**: Items replace all parent items (cascade barrier).
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
struct StatusBarItemsModifier<Content: View>: View {
    /// The content view.
    let content: Content

    /// The status bar items to display.
    let items: [any StatusBarItemProtocol]

    /// The composition strategy for combining with parent items.
    let composition: StatusBarItemComposition

    /// Optional context identifier for legacy push/pop API.
    /// Nil for the new composition-based API.
    let context: String?

    var body: Never {
        fatalError("StatusBarItemsModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension StatusBarItemsModifier: Renderable {
    func renderToBuffer(context renderContext: RenderContext) -> FrameBuffer {
        let statusBar = renderContext.environment.statusBar

        // Set the items silently (without triggering re-render) to avoid render loops.
        // The modifier is called during rendering, so we must not trigger another render.
        if let contextName = self.context {
            // Legacy: push items to a named context
            statusBar.pushSilently(context: contextName, items: items)
        } else {
            // Register items with the focus section's composition strategy.
            // If inside a focus section, items are associated with that section.
            // Otherwise, they become global items.
            if let sectionID = renderContext.activeFocusSectionID {
                statusBar.registerSectionItems(
                    sectionID: sectionID,
                    items: items,
                    composition: composition
                )
            } else {
                statusBar.setItemsSilently(items)
            }
        }

        return TUIkit.renderToBuffer(content, context: renderContext)
    }
}
