//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ModifiedContent.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - ModifiedContent

/// A value with a modifier applied to it.
///
/// `ModifiedContent` matches SwiftUI's public shape: an unconstrained pair of
/// content and modifier that conforms to ``View`` when its content is a view
/// and its modifier is a ``ViewModifier``. It is the return type of
/// ``View/modifier(_:)``; users normally never construct it directly.
public struct ModifiedContent<Content, Modifier> {
    /// The content that the modifier transforms.
    public var content: Content

    /// The view modifier applied to the content.
    public var modifier: Modifier

    /// Creates a modified content value from a content value and a modifier.
    ///
    /// - Parameters:
    ///   - content: The content that the modifier changes.
    ///   - modifier: The modifier to apply.
    public init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }
}

// MARK: - Equatable Conformance

extension ModifiedContent: Equatable where Content: Equatable, Modifier: Equatable {}

// MARK: - View Conformance

extension ModifiedContent: View where Content: View, Modifier: ViewModifier {
    /// Never called — rendering is handled by `Renderable` conformance.
    public var body: Never {
        fatalError("ModifiedContent renders via Renderable")
    }
}

// MARK: - Rendering

extension ModifiedContent: Renderable where Content: View, Modifier: ViewModifier {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // The placeholder resolves to the stored content at whatever tree
        // position (and with whatever environment) the modifier body placed
        // it. The modifier body itself renders under a child identity so
        // state and lifecycle inside the body stay structurally stable.
        let content = self.content
        let placeholder = _ViewModifier_Content<Modifier>(renderContent: { placeholderContext in
            TUIkitView.renderToBuffer(content, context: placeholderContext)
        })
        let bodyView = modifier.body(content: placeholder)
        let bodyContext = context.withChildIdentity(type: Modifier.Body.self)
        return TUIkitView.renderToBuffer(bodyView, context: bodyContext)
    }
}
