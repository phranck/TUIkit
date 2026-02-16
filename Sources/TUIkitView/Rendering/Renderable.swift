//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Renderable.swift
//
//  Created by LAYERED.work
//  License: MIT

import Observation
import TUIkitCore

// MARK: - Renderable Protocol

/// A protocol for views that produce terminal output directly.
///
/// TUIkit uses a **dual rendering system** inspired by SwiftUI:
///
/// - **`View.body`** — Compositional path: views declare *what* they
///   are made of by composing other `View` types.
/// - **`Renderable.renderToBuffer`** — Primitive path: views define
///   *how* they look by producing a ``FrameBuffer`` directly.
///
/// When the free function ``renderToBuffer(_:context:)`` encounters a
/// view, it checks `Renderable` conformance **first**. If the view
/// conforms, `renderToBuffer(context:)` is called and `body` is never
/// consulted. Only if the view is *not* `Renderable` does the function
/// recurse into `body`.
///
/// ## Who conforms to Renderable?
///
/// - **Leaf views**: `Text`, `EmptyView`, `Spacer`, `Divider`
/// - **Layout containers**: `VStack`, `HStack`, `ZStack`
/// - **ViewBuilder glue**: `TupleView`, `ConditionalView`, `ViewArray`
/// - **Interactive views**: `Button`, `ButtonRow`, `Menu`, `StatusBar`
/// - **Containers**: `Panel`, `ContainerView`, `Alert`, `Dialog`, `Card`
/// - **Modifiers**: `ModifiedView`, `DimmedModifier`, etc.
///
/// All of these declare `body: Never` (which `fatalError`s) because
/// their rendering is fully handled by `Renderable`.
///
/// ## Composite views (body only)
///
/// Views that do **not** conform to `Renderable` use `body` to compose
/// other views. Example: `Box` returns `content.border(...)` from its
/// `body`, delegating rendering to `ContainerView` which *is* `Renderable`.
///
/// ## Adding a new view type
///
/// - If your view composes other views → implement `body`, skip `Renderable`.
/// - If your view produces terminal output directly → conform to `Renderable`
///   and set `body: Never`.
/// - **Warning**: A view with `body: Never` that does *not* conform to
///   `Renderable` will silently render as empty. There is no runtime error.
@MainActor
public protocol Renderable {
    /// Renders this view into a ``FrameBuffer``.
    ///
    /// Called by the free function ``renderToBuffer(_:context:)`` when
    /// the view conforms to `Renderable`. The `body` property is never
    /// consulted in this case.
    ///
    /// - Parameter context: The rendering context with layout constraints,
    ///   environment values, and the `TUIContext`.
    /// - Returns: A buffer containing the rendered terminal output.
    func renderToBuffer(context: RenderContext) -> FrameBuffer
}

// MARK: - Layoutable Protocol

/// A protocol for views that support two-pass layout.
///
/// Views conforming to `Layoutable` can participate in the two-pass layout system:
/// 1. **Measure pass**: `sizeThatFits` is called to determine how much space the view needs
/// 2. **Layout pass**: `renderToBuffer` is called with the final allocated size
///
/// This enables proper layout distribution in containers like HStack and VStack,
/// where flexible views (Spacer, TextField) share remaining space after fixed
/// views (Text, Button) have claimed their natural size.
///
/// ## Conformance
///
/// Views that conform to `Layoutable` must also conform to `Renderable`.
/// The `sizeThatFits` method should return consistent results with what
/// `renderToBuffer` actually produces.
///
/// ## Default Implementation
///
/// Views that don't implement `sizeThatFits` get a default implementation
/// that renders the view and measures the resulting buffer. This is less
/// efficient but ensures backward compatibility.
@MainActor
public protocol Layoutable: Renderable {
    /// Returns the size this view needs given a proposed size.
    ///
    /// Called during the measure pass of two-pass layout. The view should
    /// return its ideal size, optionally constrained by the proposal.
    ///
    /// - Parameters:
    ///   - proposal: The size proposed by the parent (nil dimensions mean "use ideal").
    ///   - context: The rendering context.
    /// - Returns: The size this view needs and whether it's flexible.
    func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize
}

// MARK: - Default Layoutable Implementation

extension Layoutable {
    /// Default implementation that renders the view to measure its size.
    ///
    /// This fallback ensures backward compatibility but is less efficient
    /// than a proper `sizeThatFits` implementation that calculates size
    /// without rendering.
    public func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize {
        // Create a context with proposed dimensions if available
        var measureContext = context
        if let width = proposal.width {
            measureContext.availableWidth = width
        }
        if let height = proposal.height {
            measureContext.availableHeight = height
        }

        // Render to measure
        let buffer = renderToBuffer(context: measureContext)
        return ViewSize.fixed(buffer.width, buffer.height)
    }
}

// MARK: - Rendering Dispatch

/// Renders any `View` into a ``FrameBuffer`` using the dual rendering system.
///
/// This is the **single entry point** for all view rendering in TUIkit.
/// Every recursive call in the view tree passes through this function.
///
/// ## Decision order
///
/// 1. **Renderable** — If the view conforms to ``Renderable``, call
///    `renderToBuffer(context:)` directly. The `body` property is
///    never accessed.
/// 2. **Body recursion** — If the view does *not* conform to `Renderable`
///    and its `Body` type is not `Never`, recurse into `view.body`.
/// 3. **Empty fallback** — If neither applies (`Body` is `Never` and no
///    `Renderable` conformance), return an empty ``FrameBuffer``.
///    This is a silent no-op — no error, no warning.
///
/// ## Example flow
///
/// ```
/// renderToBuffer(Box { Text("Hi") })
///   → Box is NOT Renderable, Body != Never
///   → recurse into Box.body → ContainerView
///     → ContainerView IS Renderable
///     → calls ContainerView.renderToBuffer(context:)
///       → internally calls renderToBuffer(Text("Hi"), context:)
///         → Text IS Renderable → produces FrameBuffer
/// ```
///
/// - Parameters:
///   - view: The view to render.
///   - context: The rendering context with layout constraints.
/// - Returns: A ``FrameBuffer`` containing the rendered terminal output.
@MainActor
public func renderToBuffer<V: View>(_ view: V, context: RenderContext) -> FrameBuffer {
    // Priority 1: Direct rendering via Renderable protocol
    if let renderable = view as? Renderable {
        return renderable.renderToBuffer(context: context)
    }

    // Priority 2: Composite view — set up hydration context and recurse into body.
    //
    // Before evaluating `body`, we activate the hydration context so that any
    // @State properties created during body evaluation self-hydrate from StateStorage.
    //
    // For the view's OWN @State properties: these were already hydrated when the
    // view was constructed (either via self-hydrating init if activeContext was set,
    // or via the parent's body evaluation context). The context here is for CHILDREN
    // that will be constructed inside this view's body.
    if V.Body.self != Never.self {
        let childContext = context.withChildIdentity(type: V.Body.self)

        // Wrap body evaluation in observation tracking so that any @Observable
        // property accessed during body triggers a re-render when mutated.
        let body = StateRegistration.withHydration(context: context) {
            withObservationTracking {
                view.body
            } onChange: {
                AppState.shared.setNeedsRenderWithCacheClear()
            }
        }

        context.environment.stateStorage!.markActive(context.identity)

        return renderToBuffer(body, context: childContext)
    }

    // Priority 3: No rendering path — return empty buffer silently.
    // This happens for types with body: Never that forgot Renderable conformance.
    return FrameBuffer()
}
