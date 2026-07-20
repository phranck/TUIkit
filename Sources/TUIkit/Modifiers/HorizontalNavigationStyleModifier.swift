//  🖥️ TUIKit — Terminal UI Kit for Swift
//  HorizontalNavigationStyleModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A modifier that sets the horizontal (Tab/section) keyboard navigation style
/// for focusable views in this subtree.
///
/// Applied via `.horizontalNavigationStyle(_:)` on any view.
public struct HorizontalNavigationStyleModifier<Content: View>: View {
    /// The content to wrap.
    let content: Content

    /// The active horizontal navigation styles.
    let styles: Set<HorizontalNavigationStyle>

    public var body: Never {
        fatalError("HorizontalNavigationStyleModifier renders via Renderable")
    }
}

// MARK: - Equatable

extension HorizontalNavigationStyleModifier: @preconcurrency Equatable where Content: Equatable {
    public static func == (
        lhs: HorizontalNavigationStyleModifier<Content>,
        rhs: HorizontalNavigationStyleModifier<Content>
    ) -> Bool {
        lhs.content == rhs.content && lhs.styles == rhs.styles
    }
}

// MARK: - Renderable

extension HorizontalNavigationStyleModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let modifiedEnvironment = context.environment.setting(\.horizontalNavigationStyles, to: styles)
        let modifiedContext = context.withEnvironment(modifiedEnvironment)
        // Propagate to FocusManager so Tab and vim h/l are gated correctly.
        context.environment.focusManager.horizontalNavigationStyles = styles
        return TUIkit.renderToBuffer(content, context: modifiedContext)
    }
}
