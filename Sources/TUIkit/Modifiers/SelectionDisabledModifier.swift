//  🖥️ TUIKit — Terminal UI Kit for Swift
//  SelectionDisabledModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A modifier that disables selection for a view within a List.
///
/// When applied to a list row, this modifier prevents that row from being
/// selected. Focus navigation will skip over selection-disabled rows.
///
/// ## Usage
///
/// ```swift
/// List(selection: $selection) {
///     Text("Selectable")
///     Text("Disabled")
///         .selectionDisabled()
///     Text("Also Selectable")
/// }
/// ```
///
/// ## Visual Appearance
///
/// Selection-disabled rows render with dimmed foreground color to indicate
/// they cannot be selected.
public struct SelectionDisabledModifier<Content: View>: View {
    /// The content to apply selection disabled to.
    let content: Content

    /// Whether selection is disabled.
    let isDisabled: Bool

    public var body: Never {
        fatalError("SelectionDisabledModifier renders via Renderable")
    }
}

// MARK: - Equatable

extension SelectionDisabledModifier: @preconcurrency Equatable where Content: Equatable {
    public static func == (lhs: SelectionDisabledModifier<Content>, rhs: SelectionDisabledModifier<Content>) -> Bool {
        lhs.content == rhs.content && lhs.isDisabled == rhs.isDisabled
    }
}

// MARK: - Renderable

extension SelectionDisabledModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Create modified environment with selection disabled state.
        let modifiedEnvironment = context.environment.setting(\.isSelectionDisabled, to: isDisabled)
        let modifiedContext = context.withEnvironment(modifiedEnvironment)

        // Render content with the modified environment.
        return TUIkit.renderToBuffer(content, context: modifiedContext)
    }
}
