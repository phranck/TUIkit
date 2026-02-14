//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderContext.swift
//
//  Created by LAYERED.work
//  License: MIT

/// The context for rendering a view.
///
/// Contains layout constraints, environment values, and the central
/// `TUIContext` that views need to determine their size, content, and
/// access framework services.
///
/// `RenderContext` is a pure data container — it does not hold a reference
/// to `Terminal`. All terminal I/O happens in `RenderLoop` after the
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
    /// Used by `StateStorage` to persist `@State` values across render passes.
    var identity: ViewIdentity

    /// The ID of the focus section that child views should register in.
    ///
    /// Set by `FocusSectionModifier` during rendering. Focusable children
    /// (buttons, menus) read this to register in the correct section.
    /// When nil, elements register in the active or default section.
    var activeFocusSectionID: String?

    /// The current breathing animation phase (0–1) for the focus indicator.
    ///
    /// Set by `RenderLoop` from the `PulseTimer` at the start of each frame.
    /// Read by `BorderRenderer` to interpolate the ● indicator color.
    /// A value of 0 means dimmest, 1 means brightest.
    var pulsePhase: Double = 0

    /// The cursor timer for TextField/SecureField animations.
    ///
    /// Set by `RenderLoop` at the start of each frame.
    /// Read by text fields to compute blink and pulse phases.
    var cursorTimer: CursorTimer?

    /// The focus indicator color for the first border encountered in this subtree.
    ///
    /// Set by `FocusSectionModifier` when the section is active.
    /// The first view that renders a border (Panel, Box, `.border()`) reads
    /// this color, renders the ● indicator, and sets it to nil so that
    /// nested borders don't also show the indicator.
    var focusIndicatorColor: Color?

    /// Whether an explicit frame width constraint has been set.
    ///
    /// Set by `FlexibleFrameView` when a fixed width is specified.
    /// Container views use this to decide whether to expand to fill
    /// the available width or shrink to fit their content.
    var hasExplicitWidth: Bool = false

    /// Whether an explicit frame height constraint has been set.
    ///
    /// Set by layout containers (e.g., NavigationSplitView) when a fixed height is specified.
    /// Container views use this to decide whether to expand to fill
    /// the available height or shrink to fit their content.
    var hasExplicitHeight: Bool = false

    /// Whether this is a measurement pass (no side-effects should occur).
    ///
    /// Set to true during two-pass layout when measuring non-Layoutable views.
    /// Views should skip side-effects like focus registration when this is true.
    var isMeasuring: Bool = false

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
    /// Used by `ConditionalView` to distinguish between if/else branches.
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
    /// throwaway `FocusManager` and `KeyEventDispatcher` while sharing
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
