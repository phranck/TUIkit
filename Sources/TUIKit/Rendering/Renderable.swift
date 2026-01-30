//
//  Renderable.swift
//  TUIKit
//
//  Protocol for views that can render themselves directly.
//

/// A protocol for views that produce terminal output directly.
///
/// TUIKit uses a **dual rendering system** inspired by SwiftUI:
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
/// - **Modifiers**: `ModifiedView`, `BorderedView`, `DimmedModifier`, etc.
///
/// All of these declare `body: Never` (which `fatalError`s) because
/// their rendering is fully handled by `Renderable`.
///
/// ## Composite views (body only)
///
/// Views that do **not** conform to `Renderable` use `body` to compose
/// other views. Example: ``Box`` returns `content.border(...)` from its
/// `body`, delegating rendering to `BorderedView` which *is* `Renderable`.
///
/// ## Adding a new view type
///
/// - If your view composes other views → implement `body`, skip `Renderable`.
/// - If your view produces terminal output directly → conform to `Renderable`
///   and set `body: Never`.
/// - **Warning**: A view with `body: Never` that does *not* conform to
///   `Renderable` will silently render as empty. There is no runtime error.
public protocol Renderable {
    /// Renders this view into a ``FrameBuffer``.
    ///
    /// Called by the free function ``renderToBuffer(_:context:)`` when
    /// the view conforms to `Renderable`. The `body` property is never
    /// consulted in this case.
    ///
    /// - Parameter context: The rendering context with layout constraints,
    ///   environment values, and the ``TUIContext``.
    /// - Returns: A buffer containing the rendered terminal output.
    func renderToBuffer(context: RenderContext) -> FrameBuffer
}

/// The context for rendering a view.
///
/// Contains layout constraints, terminal information, environment values,
/// and the central ``TUIContext`` that views need to determine their size,
/// content, and access framework services.
public struct RenderContext {
    /// The target terminal.
    public let terminal: Terminal

    /// The available width in characters.
    public var availableWidth: Int

    /// The available height in lines.
    public var availableHeight: Int

    /// The environment values for this render pass.
    public var environment: EnvironmentValues

    /// The central dependency container for framework services.
    ///
    /// Provides access to lifecycle tracking, key event dispatch,
    /// and preference storage without relying on singletons.
    public let tuiContext: TUIContext

    /// Creates a new RenderContext.
    ///
    /// - Parameters:
    ///   - terminal: The target terminal.
    ///   - availableWidth: The available width (defaults to terminal width).
    ///   - availableHeight: The available height (defaults to terminal height).
    ///   - environment: The environment values (defaults to empty).
    ///   - tuiContext: The TUI context (defaults to a fresh instance).
    public init(
        terminal: Terminal = .shared,
        availableWidth: Int? = nil,
        availableHeight: Int? = nil,
        environment: EnvironmentValues = EnvironmentValues(),
        tuiContext: TUIContext = TUIContext()
    ) {
        self.terminal = terminal
        self.availableWidth = availableWidth ?? terminal.width
        self.availableHeight = availableHeight ?? terminal.height
        self.environment = environment
        self.tuiContext = tuiContext
    }

    /// Creates a new context with the same terminal and size but different environment.
    ///
    /// - Parameter environment: The new environment values.
    /// - Returns: A new RenderContext with the updated environment.
    public func withEnvironment(_ environment: EnvironmentValues) -> Self {
        Self(
            terminal: terminal,
            availableWidth: availableWidth,
            availableHeight: availableHeight,
            environment: environment,
            tuiContext: tuiContext
        )
    }
}

// MARK: - Rendering Dispatch

/// Renders any `View` into a ``FrameBuffer`` using the dual rendering system.
///
/// This is the **single entry point** for all view rendering in TUIKit.
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
///   → recurse into Box.body → BorderedView
///     → BorderedView IS Renderable
///     → calls BorderedView.renderToBuffer(context:)
///       → internally calls renderToBuffer(Text("Hi"), context:)
///         → Text IS Renderable → produces FrameBuffer
/// ```
///
/// - Parameters:
///   - view: The view to render.
///   - context: The rendering context with layout constraints.
/// - Returns: A ``FrameBuffer`` containing the rendered terminal output.
public func renderToBuffer<V: View>(_ view: V, context: RenderContext) -> FrameBuffer {
    // Priority 1: Direct rendering via Renderable protocol
    if let renderable = view as? Renderable {
        return renderable.renderToBuffer(context: context)
    }

    // Priority 2: Composite view — recurse into body
    if V.Body.self != Never.self {
        return renderToBuffer(view.body, context: context)
    }

    // Priority 3: No rendering path — return empty buffer silently.
    // This happens for types with body: Never that forgot Renderable conformance.
    return FrameBuffer()
}
