//
//  View.swift
//  TUIKit
//
//  The base protocol for all TUIKit views.
//

/// The base protocol for all TUIKit views.
///
/// `View` is the central protocol in TUIKit and works similarly to `View` in SwiftUI.
/// It defines how components declare their structure and content.
///
/// Every View defines a `body` composed of other Views.
/// This enables a hierarchical, declarative UI description.
///
/// ## Dual Rendering System
///
/// TUIKit uses two rendering paths:
///
/// - **Composite views** implement `body` to compose other views.
///   The rendering system recurses into `body` to resolve the tree.
/// - **Primitive views** additionally conform to ``Renderable`` and
///   produce a ``FrameBuffer`` directly. They set `body: Never`
///   (which `fatalError`s if called) because their `body` is never used.
///
/// The free function ``renderToBuffer(_:context:)`` checks `Renderable`
/// first, then falls back to `body`. See ``Renderable`` for details.
///
/// ## Creating a composite view
///
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         Text("Hello, TUIKit!")
///     }
/// }
/// ```
///
/// ## Creating a primitive view
///
/// ```swift
/// struct MyPrimitive: View {
///     var body: Never { fatalError() }
/// }
///
/// extension MyPrimitive: Renderable {
///     func renderToBuffer(context: RenderContext) -> FrameBuffer {
///         FrameBuffer(text: "output")
///     }
/// }
/// ```
public protocol View {
    /// The type of the body view.
    ///
    /// Swift automatically infers this type from the `body` implementation.
    /// Primitive views that conform to ``Renderable`` set this to `Never`.
    associatedtype Body: View

    /// The content and behavior of this view.
    ///
    /// Implement this property to define the structure of your view
    /// by composing other `View` types.
    ///
    /// For primitive views that conform to ``Renderable``, set this
    /// to `Never` with a `fatalError` body. The rendering system will
    /// call ``Renderable/renderToBuffer(context:)`` instead.
    @ViewBuilder
    var body: Body { get }
}
