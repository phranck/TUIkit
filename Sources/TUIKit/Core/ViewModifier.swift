//
//  ViewModifier.swift
//  TUIKit
//
//  The view modifier system for transforming views.
//

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
public protocol ViewModifier {
    /// Transforms a rendered buffer.
    ///
    /// - Parameters:
    ///   - buffer: The rendered content of the wrapped view.
    ///   - context: The rendering context.
    /// - Returns: The modified buffer.
    func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer
}

// MARK: - ModifiedView

/// A view that wraps another view with a modifier.
///
/// This is the return type of modifier methods like `.frame()` and `.padding()`.
/// It is created automatically — users don't instantiate this directly.
///
/// `ModifiedView` is a **primitive view**: it declares `body: Never`
/// and conforms to ``Renderable``. The rendering system calls
/// ``Renderable/renderToBuffer(context:)`` which first renders the
/// wrapped `content`, then applies the modifier's transformation.
/// The `body` property is never called.
public struct ModifiedView<Content: View, Modifier: ViewModifier>: View {
    /// The original view.
    public let content: Content

    /// The modifier to apply.
    public let modifier: Modifier

    /// Never called — rendering is handled by ``Renderable`` conformance.
    public var body: Never {
        fatalError("ModifiedView renders via Renderable")
    }
}

// MARK: - ModifiedView Rendering

extension ModifiedView: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let childBuffer = TUIKit.renderToBuffer(content, context: context)
        return modifier.modify(buffer: childBuffer, context: context)
    }
}
