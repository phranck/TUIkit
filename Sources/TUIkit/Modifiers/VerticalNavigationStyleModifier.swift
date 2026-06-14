//  🖥️ TUIKit — Terminal UI Kit for Swift
//  VerticalNavigationStyleModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A modifier that sets the vertical (up/down) keyboard navigation style
/// for scrollable views in this subtree.
///
/// Applied via `.verticalNavigationStyle(_:)` on any view.
public struct VerticalNavigationStyleModifier<Content: View>: View {
    /// The content to wrap.
    let content: Content

    /// The active vertical navigation styles.
    let styles: Set<VerticalNavigationStyle>

    public var body: Never {
        fatalError("VerticalNavigationStyleModifier renders via Renderable")
    }
}

// MARK: - Equatable

extension VerticalNavigationStyleModifier: @preconcurrency Equatable where Content: Equatable {
    public static func == (
        lhs: VerticalNavigationStyleModifier<Content>,
        rhs: VerticalNavigationStyleModifier<Content>
    ) -> Bool {
        lhs.content == rhs.content && lhs.styles == rhs.styles
    }
}

// MARK: - Renderable

extension VerticalNavigationStyleModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let modifiedEnvironment = context.environment.setting(\.verticalNavigationStyles, to: styles)
        let modifiedContext = context.withEnvironment(modifiedEnvironment)
        // Propagate to FocusManager for section-level fallback navigation (VStack, etc.).
        context.environment.focusManager.verticalNavigationStyles = styles
        return TUIkit.renderToBuffer(content, context: modifiedContext)
    }
}
