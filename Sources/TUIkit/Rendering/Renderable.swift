//
//  Renderable.swift
//  TUIkit
//
//  Protocol for views that can render themselves directly.
//

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
protocol Renderable {
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
/// Contains layout constraints, environment values, and the central
/// `TUIContext` that views need to determine their size, content, and
/// access framework services.
///
/// `RenderContext` is a pure data container — it does not hold a reference
/// to `Terminal`. All terminal I/O happens in ``RenderLoop`` after the
/// view tree has been rendered into a ``FrameBuffer``.
///
/// - Important: This is framework infrastructure passed to
///   ``ViewModifier/modify(buffer:context:)``. Most developers only need
///   ``availableWidth``, ``availableHeight``, and ``environment``.
public struct RenderContext {
    /// The available width in characters.
    public var availableWidth: Int

    /// The available height in lines.
    public var availableHeight: Int

    /// The environment values for this render pass.
    public var environment: EnvironmentValues

    /// The central dependency container for framework services.
    ///
    /// Provides access to lifecycle tracking, key event dispatch,
    /// and preference storage via constructor injection.
    /// Mutable to allow modal presentation to substitute an isolated
    /// context for background content rendering.
    var tuiContext: TUIContext

    /// The current view's structural identity in the render tree.
    ///
    /// Built incrementally as `renderToBuffer` traverses the view hierarchy.
    /// Container views append child indices, composite views append type names.
    /// Used by ``StateStorage`` to persist `@State` values across render passes.
    var identity: ViewIdentity

    /// The ID of the focus section that child views should register in.
    ///
    /// Set by ``FocusSectionModifier`` during rendering. Focusable children
    /// (buttons, menus) read this to register in the correct section.
    /// When nil, elements register in the active or default section.
    var activeFocusSectionID: String?

    /// The current breathing animation phase (0–1) for the focus indicator.
    ///
    /// Set by ``RenderLoop`` from the ``PulseTimer`` at the start of each frame.
    /// Read by ``BorderRenderer`` to interpolate the ● indicator color.
    /// A value of 0 means dimmest, 1 means brightest.
    var pulsePhase: Double = 0

    /// The focus indicator color for the first border encountered in this subtree.
    ///
    /// Set by ``FocusSectionModifier`` when the section is active.
    /// The first view that renders a border (Panel, Box, `.border()`) reads
    /// this color, renders the ● indicator, and sets it to nil so that
    /// nested borders don't also show the indicator.
    var focusIndicatorColor: Color?

    /// Creates a new RenderContext.
    ///
    /// - Parameters:
    ///   - availableWidth: The available width in characters.
    ///   - availableHeight: The available height in lines.
    ///   - environment: The environment values (defaults to empty).
    ///   - tuiContext: The TUI context (defaults to a fresh instance).
    ///   - identity: The view identity path (defaults to root).
    init(
        availableWidth: Int,
        availableHeight: Int,
        environment: EnvironmentValues = EnvironmentValues(),
        tuiContext: TUIContext = TUIContext(),
        identity: ViewIdentity = ViewIdentity(path: "")
    ) {
        self.availableWidth = availableWidth
        self.availableHeight = availableHeight
        self.environment = environment
        self.tuiContext = tuiContext
        self.identity = identity
    }

    /// Creates a new context with the same size but different environment.
    ///
    /// - Parameter environment: The new environment values.
    /// - Returns: A new RenderContext with the updated environment.
    func withEnvironment(_ environment: EnvironmentValues) -> Self {
        var copy = self
        copy.environment = environment
        return copy
    }

    /// Creates a new context with a child identity for the given type and index.
    ///
    /// Used by container views (`TupleView`, `ViewArray`) to assign
    /// structural identities to their children.
    ///
    /// - Parameters:
    ///   - type: The child view's type.
    ///   - index: The child's position within the container.
    /// - Returns: A new RenderContext with the extended identity path.
    func withChildIdentity<V>(type: V.Type, index: Int) -> Self {
        var copy = self
        copy.identity = identity.child(type: type, index: index)
        return copy
    }

    /// Creates a new context with a child identity for a composite view's body.
    ///
    /// Used when descending into a view's `body` where there is exactly
    /// one child (no sibling disambiguation needed).
    ///
    /// - Parameter type: The child view's type.
    /// - Returns: A new RenderContext with the extended identity path.
    func withChildIdentity<V>(type: V.Type) -> Self {
        var copy = self
        copy.identity = identity.child(type: type)
        return copy
    }

    /// Creates a new context with a branch identity.
    ///
    /// Used by ``ConditionalView`` to distinguish between if/else branches.
    ///
    /// - Parameter label: The branch label (`"true"` or `"false"`).
    /// - Returns: A new RenderContext with the branch identity.
    func withBranchIdentity(_ label: String) -> Self {
        var copy = self
        copy.identity = identity.branch(label)
        return copy
    }

    /// Creates a context isolated from the real focus and key event systems.
    ///
    /// Used by modal presentation modifiers to render background content
    /// visually without letting its buttons and key handlers interfere
    /// with the modal's interactive elements. The returned context has a
    /// throwaway ``FocusManager`` and ``KeyEventDispatcher`` while sharing
    /// lifecycle, preferences, and state storage with the real context.
    func isolatedForBackground() -> RenderContext {
        var copy = self
        copy.environment.focusManager = FocusManager()
        copy.tuiContext = TUIContext(
            lifecycle: tuiContext.lifecycle,
            keyEventDispatcher: KeyEventDispatcher(),
            preferences: tuiContext.preferences,
            stateStorage: tuiContext.stateStorage
        )
        return copy
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
func renderToBuffer<V: View>(_ view: V, context: RenderContext) -> FrameBuffer {
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

        // Save previous hydration state (supports nested composite views).
        let previousContext = StateRegistration.activeContext
        let previousCounter = StateRegistration.counter

        // Activate hydration: @State.init will use this to look up persistent storage.
        StateRegistration.activeContext = HydrationContext(
            identity: context.identity,
            storage: context.tuiContext.stateStorage
        )
        StateRegistration.counter = 0

        let body = view.body

        // Restore previous hydration state and mark this identity as active for GC.
        StateRegistration.activeContext = previousContext
        StateRegistration.counter = previousCounter
        context.tuiContext.stateStorage.markActive(context.identity)

        return renderToBuffer(body, context: childContext)
    }

    // Priority 3: No rendering path — return empty buffer silently.
    // This happens for types with body: Never that forgot Renderable conformance.
    return FrameBuffer()
}
