//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Renderable.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Layout Types

/// How much space a parent proposes to a child view.
///
/// Similar to SwiftUI's `ProposedViewSize`. The parent suggests dimensions,
/// and the child can accept, ignore, or partially use them.
///
/// - `nil` means "use your ideal size" (no constraint)
/// - A specific value means "try to fit in this space"
public struct ProposedSize: Equatable, Sendable {
    /// The proposed width in characters, or nil for ideal width.
    public var width: Int?

    /// The proposed height in lines, or nil for ideal height.
    public var height: Int?

    /// No constraints - view should use its ideal size.
    public static let unspecified = ProposedSize(width: nil, height: nil)

    /// Creates a proposed size with specific dimensions.
    public init(width: Int?, height: Int?) {
        self.width = width
        self.height = height
    }

    /// Creates a proposed size with fixed dimensions.
    public static func fixed(_ width: Int, _ height: Int) -> ProposedSize {
        ProposedSize(width: width, height: height)
    }
}

/// The size a view needs and whether it can flex.
///
/// Views return this from `sizeThatFits` to communicate their space requirements.
/// Flexible views (like Spacer, TextField) can expand to fill available space.
/// Fixed views (like Text, Button) have a specific size they need.
public struct ViewSize: Equatable, Sendable {
    /// The width this view needs (minimum if flexible).
    public var width: Int

    /// The height this view needs (minimum if flexible).
    public var height: Int

    /// Whether this view can expand horizontally to fill available space.
    public var isWidthFlexible: Bool

    /// Whether this view can expand vertically to fill available space.
    public var isHeightFlexible: Bool

    /// Creates a view size with explicit flexibility flags.
    public init(width: Int, height: Int, isWidthFlexible: Bool = false, isHeightFlexible: Bool = false) {
        self.width = width
        self.height = height
        self.isWidthFlexible = isWidthFlexible
        self.isHeightFlexible = isHeightFlexible
    }

    /// Creates a fixed-size view that doesn't expand.
    public static func fixed(_ width: Int, _ height: Int) -> ViewSize {
        ViewSize(width: width, height: height, isWidthFlexible: false, isHeightFlexible: false)
    }

    /// Creates a flexible view that expands to fill available space.
    public static func flexible(minWidth: Int = 0, minHeight: Int = 0) -> ViewSize {
        ViewSize(width: minWidth, height: minHeight, isWidthFlexible: true, isHeightFlexible: true)
    }

    /// Creates a view that is flexible only horizontally.
    public static func flexibleWidth(minWidth: Int = 0, height: Int) -> ViewSize {
        ViewSize(width: minWidth, height: height, isWidthFlexible: true, isHeightFlexible: false)
    }

    /// Creates a view that is flexible only vertically.
    public static func flexibleHeight(width: Int, minHeight: Int = 0) -> ViewSize {
        ViewSize(width: width, height: minHeight, isWidthFlexible: false, isHeightFlexible: true)
    }
}

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
/// other views. Example: ``Box`` returns `content.border(...)` from its
/// `body`, delegating rendering to ``ContainerView`` which *is* `Renderable`.
///
/// ## Adding a new view type
///
/// - If your view composes other views → implement `body`, skip `Renderable`.
/// - If your view produces terminal output directly → conform to `Renderable`
///   and set `body: Never`.
/// - **Warning**: A view with `body: Never` that does *not* conform to
///   `Renderable` will silently render as empty. There is no runtime error.
@MainActor
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
protocol Layoutable: Renderable {
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
    func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize {
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

    /// The cursor timer for TextField/SecureField animations.
    ///
    /// Set by ``RenderLoop`` at the start of each frame.
    /// Read by text fields to compute blink and pulse phases.
    var cursorTimer: CursorTimer?

    /// The focus indicator color for the first border encountered in this subtree.
    ///
    /// Set by ``FocusSectionModifier`` when the section is active.
    /// The first view that renders a border (Panel, Box, `.border()`) reads
    /// this color, renders the ● indicator, and sets it to nil so that
    /// nested borders don't also show the indicator.
    var focusIndicatorColor: Color?

    /// Whether an explicit frame width constraint has been set.
    ///
    /// Set by ``FlexibleFrameView`` when a fixed width is specified.
    /// Container views use this to decide whether to expand to fill
    /// the available width or shrink to fit their content.
    var hasExplicitWidth: Bool = false

    /// Whether an explicit frame height constraint has been set.
    ///
    /// Set by layout containers (e.g., NavigationSplitView) when a fixed height is specified.
    /// Container views use this to decide whether to expand to fill
    /// the available height or shrink to fit their content.
    var hasExplicitHeight: Bool = false

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
    func isolatedForBackground() -> Self {
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

    /// Creates a new context with a different available width.
    ///
    /// Used by layout containers (e.g., NavigationSplitView) to constrain
    /// child views to a specific column width.
    ///
    /// This also sets `hasExplicitWidth` to true so that child views
    /// (like List) know to expand to fill the available width.
    ///
    /// - Parameter width: The new available width in characters.
    /// - Returns: A new RenderContext with the updated width.
    func withAvailableWidth(_ width: Int) -> Self {
        var copy = self
        copy.availableWidth = width
        copy.hasExplicitWidth = true
        return copy
    }

    /// Creates a copy with updated available height.
    ///
    /// Used by layout containers (e.g., NavigationSplitView) to constrain
    /// child views to a specific height.
    ///
    /// This also sets `hasExplicitHeight` to true so that child views
    /// (like List) know to expand to fill the available height.
    ///
    /// - Parameter height: The new available height in lines.
    /// - Returns: A new RenderContext with the updated height.
    func withAvailableHeight(_ height: Int) -> Self {
        var copy = self
        copy.availableHeight = height
        copy.hasExplicitHeight = true
        return copy
    }

    /// Creates a copy with updated available width and height.
    ///
    /// Used by layout containers to constrain child views to specific dimensions.
    ///
    /// - Parameters:
    ///   - width: The new available width in characters.
    ///   - height: The new available height in lines.
    /// - Returns: A new RenderContext with the updated dimensions.
    func withAvailableSize(width: Int, height: Int) -> Self {
        var copy = self
        copy.availableWidth = width
        copy.availableHeight = height
        copy.hasExplicitWidth = true
        copy.hasExplicitHeight = true
        return copy
    }

    // MARK: - Container Layout Helpers

    /// Creates a context for rendering content inside a bordered container.
    ///
    /// Subtracts the border width (2 characters for left + right) from available width.
    /// Propagates `hasExplicitWidth` from parent so children know whether to expand.
    ///
    /// - Parameter hasBorder: Whether the container has a border (default: true).
    /// - Returns: A new context with adjusted width for inner content.
    func forBorderedContent(hasBorder: Bool = true) -> Self {
        var copy = self
        if hasBorder {
            copy.availableWidth = max(0, availableWidth - 2)
        }
        // Propagate hasExplicitWidth from parent - if parent has explicit width,
        // children should also expand to fill the (reduced) available space.
        return copy
    }

    /// Calculates the inner width for a container based on content.
    ///
    /// Containers (borders, panels, cards) size to fit their content.
    /// They do not auto-expand beyond the content width.
    ///
    /// - Parameters:
    ///   - contentWidth: The natural width of the content.
    ///   - innerAvailableWidth: The available width inside the container (unused).
    /// - Returns: The content width.
    func resolveContainerWidth(contentWidth: Int, innerAvailableWidth: Int) -> Int {
        return contentWidth
    }

    /// Calculates the inner height for a container based on content.
    ///
    /// Containers size to fit their content height.
    /// They do not auto-expand to fill available space.
    ///
    /// - Parameters:
    ///   - contentHeight: The natural height of the content.
    ///   - borderOverhead: Lines used by borders/title/footer (unused, kept for API compatibility).
    /// - Returns: The content height.
    func resolveContainerHeight(contentHeight: Int, borderOverhead: Int = 0) -> Int {
        return contentHeight
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
