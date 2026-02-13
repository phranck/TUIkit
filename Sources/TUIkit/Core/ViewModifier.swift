//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A modifier that transforms a view's rendered output.
///
/// `ViewModifier` works on the `FrameBuffer` level: it takes a rendered
/// buffer and returns a transformed buffer. This allows modifiers like
/// `.padding()` and `.frame()` to manipulate layout after rendering.
///
/// # Example
///
/// ```swift
/// struct MyModifier: ViewModifier {
///     func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer {
///         // transform the buffer
///         return buffer
///     }
/// }
/// ```
@MainActor
public protocol ViewModifier {
    /// Transforms a rendered buffer.
    ///
    /// - Parameters:
    ///   - buffer: The rendered content of the wrapped view.
    ///   - context: The rendering context.
    /// - Returns: The modified buffer.
    func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer

    /// Adjusts the rendering context before the wrapped content is rendered.
    ///
    /// Override this method in modifiers that consume space (like padding)
    /// to reduce `availableWidth` or `availableHeight` so that flexible
    /// child views size themselves correctly.
    ///
    /// The default implementation returns the context unchanged.
    ///
    /// - Parameter context: The current rendering context.
    /// - Returns: The adjusted context for content rendering.
    func adjustContext(_ context: RenderContext) -> RenderContext
}

extension ViewModifier {
    public func adjustContext(_ context: RenderContext) -> RenderContext {
        context
    }
}

// MARK: - ModifiedView

/// A view that wraps another view with a modifier.
///
/// This is the return type of modifier methods like `.frame()` and `.padding()`.
/// It is created automatically — users don't instantiate this directly.
///
/// `ModifiedView` is a **primitive view**: it declares `body: Never`
/// and conforms to `Renderable`. The rendering system calls
/// `renderToBuffer(context:)` which first renders the
/// wrapped `content`, then applies the modifier's transformation.
/// The `body` property is never called.
///
/// - Important: This is framework infrastructure. Created automatically by
///   `.modifier()`. Do not instantiate directly.
public struct ModifiedView<Content: View, Modifier: ViewModifier>: View {
    /// The original view.
    public let content: Content

    /// The modifier to apply.
    public let modifier: Modifier

    /// Never called — rendering is handled by `Renderable` conformance.
    public var body: Never {
        fatalError("ModifiedView renders via Renderable")
    }
}

// MARK: - ModifiedView Rendering

extension ModifiedView: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let adjustedContext = modifier.adjustContext(context)
        let childBuffer = TUIkit.renderToBuffer(content, context: adjustedContext)
        return modifier.modify(buffer: childBuffer, context: context)
    }
}
