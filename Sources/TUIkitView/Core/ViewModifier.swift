//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - ViewModifier

/// A modifier that you apply to a view, producing a different version of it.
///
/// `ViewModifier` follows SwiftUI's contract: implement ``body(content:)``
/// and compose the received `content` placeholder with other views:
///
/// ```swift
/// struct Framed: ViewModifier {
///     func body(content: Content) -> some View {
///         VStack {
///             Divider()
///             content
///             Divider()
///         }
///     }
/// }
///
/// Text("Hello").modifier(Framed())
/// ```
///
/// Apply a modifier with ``View/modifier(_:)``, which wraps the view and the
/// modifier in a ``ModifiedContent`` value.
///
/// Terminal-specific buffer transformations (padding, background fills) are
/// framework infrastructure and live behind the internal buffer-modifier
/// layer, not behind this public protocol.
@preconcurrency
@MainActor
public protocol ViewModifier {
    /// The type of view produced by ``body(content:)``.
    associatedtype Body: View

    /// The view content placeholder passed to ``body(content:)``.
    typealias Content = _ViewModifier_Content<Self>

    /// Returns the current body of `self`, wrapping the given content.
    ///
    /// - Parameter content: A placeholder view standing in for the view this
    ///   modifier was applied to. Place it wherever the modified content
    ///   should appear.
    /// - Returns: The composed replacement view.
    @ViewBuilder
    func body(content: Self.Content) -> Self.Body
}

// MARK: - Modifier Content Placeholder

/// The placeholder view a ``ViewModifier`` receives in `body(content:)`.
///
/// Matches SwiftUI's `_ViewModifier_Content`: an opaque stand-in for the view
/// the modifier was applied to. Rendering resolves the placeholder to the
/// wrapped view captured by ``ModifiedContent``, with the environment and
/// layout constraints active at the placeholder's position in the modifier
/// body.
public struct _ViewModifier_Content<Modifier: ViewModifier>: View {
    /// Renders the wrapped content at the placeholder's tree position.
    let renderContent: (RenderContext) -> FrameBuffer

    /// Creates a placeholder resolving to the given render step.
    init(renderContent: @escaping (RenderContext) -> FrameBuffer) {
        self.renderContent = renderContent
    }

    public var body: Never {
        fatalError("_ViewModifier_Content renders via Renderable")
    }
}

extension _ViewModifier_Content: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        renderContent(context)
    }
}

// MARK: - Buffer Modifier Layer

/// A procedural modifier operating directly on rendered terminal buffers.
///
/// This is the internal layer for terminal-specific transformations that
/// cannot be expressed as view composition (padding rows, background fills).
/// Public API never exposes this protocol; user-facing modifiers go through
/// ``ViewModifier`` and ``View/modifier(_:)``.
package protocol BufferViewModifier {
    /// Transforms a rendered buffer.
    ///
    /// - Parameters:
    ///   - buffer: The rendered content of the wrapped view.
    ///   - context: The rendering context.
    /// - Returns: The modified buffer.
    @MainActor
    func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer

    /// Adjusts the rendering context before the wrapped content is rendered.
    ///
    /// Modifiers that consume space (like padding) reduce `availableWidth`
    /// or `availableHeight` here so flexible child views size themselves
    /// correctly. The default implementation returns the context unchanged.
    ///
    /// - Parameter context: The current rendering context.
    /// - Returns: The adjusted context for content rendering.
    @MainActor
    func adjustContext(_ context: RenderContext) -> RenderContext
}

extension BufferViewModifier {
    package func adjustContext(_ context: RenderContext) -> RenderContext {
        context
    }
}

// MARK: - BufferModifiedView

/// A view that applies a buffer modifier to its wrapped content.
///
/// `BufferModifiedView` is internal framework infrastructure: it renders its
/// content with the modifier-adjusted context, then applies the buffer
/// transformation. Public modifier chains produce ``ModifiedContent`` values
/// instead.
package struct BufferModifiedView<Content: View, Modifier: BufferViewModifier>: View {
    /// The original view.
    package let content: Content

    /// The buffer modifier to apply.
    package let modifier: Modifier

    /// Creates a buffer-modified view.
    ///
    /// - Parameters:
    ///   - content: The original view.
    ///   - modifier: The buffer modifier to apply.
    package init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }

    /// Never called — rendering is handled by `Renderable` conformance.
    package var body: Never {
        fatalError("BufferModifiedView renders via Renderable")
    }
}

extension BufferModifiedView: Renderable {
    package func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let adjustedContext = modifier.adjustContext(context)
        let childBuffer = TUIkitView.renderToBuffer(content, context: adjustedContext)
        return modifier.modify(buffer: childBuffer, context: context)
    }
}
