//
//  FocusSectionModifier.swift
//  TUIkit
//
//  A modifier that declares a focus section for a view subtree.
//

/// A modifier that declares a focus section for a view subtree.
///
/// Focus sections are named, focusable areas of the UI. They group interactive
/// children (buttons, menus, etc.) into a navigable unit. Tab/Shift+Tab cycles
/// between sections, while Up/Down arrows navigate within the active section.
///
/// During rendering, this modifier registers the section with the
/// ``FocusManager`` and sets the active section ID in the ``RenderContext``
/// so that child views register their focusable elements in the correct section.
///
/// ## Example
///
/// ```swift
/// HStack {
///     PlaylistView()
///         .focusSection("playlist")
///
///     TrackListView()
///         .focusSection("tracklist")
/// }
/// ```
struct FocusSectionModifier<Content: View>: View {
    /// The content view rendered within this section.
    let content: Content

    /// The unique identifier for this focus section.
    let sectionID: String

    var body: Never {
        fatalError("FocusSectionModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension FocusSectionModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let focusManager = context.environment.focusManager

        // Register the section with the focus manager (idempotent).
        focusManager.registerSection(id: sectionID)

        // Create a child context with the active section ID set,
        // so that focusable children (buttons, menus) register in this section.
        var sectionContext = context
        sectionContext.activeFocusSectionID = sectionID

        return TUIkit.renderToBuffer(content, context: sectionContext)
    }
}
