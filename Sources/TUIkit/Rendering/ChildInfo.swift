//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ChildInfo.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Child Info

/// A type-erased wrapper for a child view that enables two-pass layout.
///
/// This wrapper stores the view and allows measuring without rendering,
/// then rendering with a specific size allocation.
@MainActor
struct ChildView {
    private let _measure: (ProposedSize, RenderContext) -> ViewSize
    private let _render: (Int, Int, RenderContext) -> FrameBuffer

    /// Whether this child is a Spacer.
    let isSpacer: Bool

    /// The minimum length of this spacer (only relevant if isSpacer is true).
    let spacerMinLength: Int?

    init<V: View>(_ view: V) {
        if let spacer = view as? Spacer {
            self.isSpacer = true
            self.spacerMinLength = spacer.minLength
        } else {
            self.isSpacer = false
            self.spacerMinLength = nil
        }

        self._measure = { proposal, context in
            measureChild(view, proposal: proposal, context: context)
        }
        self._render = { width, height, context in
            renderChild(view, width: width, height: height, context: context)
        }
    }

    /// Measures this child view without rendering.
    func measure(proposal: ProposedSize, context: RenderContext) -> ViewSize {
        _measure(proposal, context)
    }

    /// Renders this child view with the given size allocation.
    func render(width: Int, height: Int, context: RenderContext) -> FrameBuffer {
        _render(width, height, context)
    }
}

/// Describes a child view within a stack for layout purposes.
struct ChildInfo {
    /// The rendered buffer of this child (nil for spacers, computed later).
    let buffer: FrameBuffer?

    /// Whether this child is a Spacer.
    let isSpacer: Bool

    /// The minimum length of this spacer (only relevant if isSpacer is true).
    let spacerMinLength: Int?

    /// The size this child needs (from sizeThatFits).
    /// Only available when using two-pass layout.
    let size: ViewSize?
}

// MARK: - Child Info Provider

/// Internal protocol that allows stack containers to extract individual
/// child info from their content (which is typically a TupleView).
@MainActor
protocol ChildInfoProvider {
    /// Returns an array of ``ChildInfo``, one per child view.
    ///
    /// - Parameter context: The rendering context for child rendering.
    /// - Returns: An array of child descriptions for layout.
    func childInfos(context: RenderContext) -> [ChildInfo]
}

// MARK: - Child View Provider

/// Protocol for views that can provide type-erased children for two-pass layout.
///
/// This enables measuring children before rendering them with final sizes.
@MainActor
protocol ChildViewProvider {
    /// Returns an array of type-erased child views for two-pass layout.
    ///
    /// - Parameter context: The rendering context (for child identity).
    /// - Returns: An array of ``ChildView`` wrappers.
    func childViews(context: RenderContext) -> [ChildView]
}

/// Creates a ChildInfo for a single view.
///
/// If the view is a ``Spacer``, the returned info marks it as such
/// with its minimum length. Otherwise the view is rendered into a
/// ``FrameBuffer`` via ``renderToBuffer(_:context:)``.
///
/// - Parameters:
///   - view: The child view.
///   - context: The rendering context.
/// - Returns: A ``ChildInfo`` describing the view.
@MainActor
func makeChildInfo<V: View>(for view: V, context: RenderContext) -> ChildInfo {
    if let spacer = view as? Spacer {
        return ChildInfo(buffer: nil, isSpacer: true, spacerMinLength: spacer.minLength, size: nil)
    }
    return ChildInfo(
        buffer: renderToBuffer(view, context: context),
        isSpacer: false,
        spacerMinLength: nil,
        size: nil
    )
}

// MARK: - Two-Pass Layout Support

/// Measures a child view without rendering it.
///
/// Uses `sizeThatFits` if the view is `Layoutable`, otherwise falls back
/// to rendering and measuring the buffer.
///
/// - Parameters:
///   - view: The child view.
///   - proposal: The proposed size from the parent.
///   - context: The rendering context.
/// - Returns: The size this view needs.
@MainActor
func measureChild<V: View>(_ view: V, proposal: ProposedSize, context: RenderContext) -> ViewSize {
    // Spacer is always flexible
    if let spacer = view as? Spacer {
        let min = spacer.minLength ?? 0
        return ViewSize(width: min, height: min, isWidthFlexible: true, isHeightFlexible: true)
    }

    // Use Layoutable if available
    if let layoutable = view as? Layoutable {
        return layoutable.sizeThatFits(proposal: proposal, context: context)
    }

    // Fallback: render to measure
    var measureContext = context
    if let width = proposal.width {
        measureContext.availableWidth = width
    }
    if let height = proposal.height {
        measureContext.availableHeight = height
    }
    let buffer = renderToBuffer(view, context: measureContext)
    return ViewSize.fixed(buffer.width, buffer.height)
}

/// Renders a child view with a specific size allocation.
///
/// - Parameters:
///   - view: The child view.
///   - width: The allocated width.
///   - height: The allocated height.
///   - context: The rendering context.
/// - Returns: The rendered buffer.
@MainActor
func renderChild<V: View>(_ view: V, width: Int, height: Int, context: RenderContext) -> FrameBuffer {
    var renderContext = context
    renderContext.availableWidth = width
    renderContext.availableHeight = height
    return renderToBuffer(view, context: renderContext)
}

// MARK: - Child Info Resolution

/// Resolves child infos from a view's content.
///
/// If the content conforms to ``ChildInfoProvider`` (e.g. TupleViews),
/// it returns individual child infos. Otherwise it returns the content
/// as a single-element array.
///
/// - Parameters:
///   - content: The content view.
///   - context: The rendering context.
/// - Returns: An array of ``ChildInfo``.
@MainActor
func resolveChildInfos<V: View>(from content: V, context: RenderContext) -> [ChildInfo] {
    if let provider = content as? ChildInfoProvider {
        return provider.childInfos(context: context)
    }
    return [makeChildInfo(for: content, context: context)]
}

// MARK: - Two-Pass Layout Resolution

/// Resolves child views from a view's content for two-pass layout.
///
/// If the content conforms to ``ChildViewProvider`` (e.g. TupleViews),
/// it returns individual child views. Otherwise it wraps the content
/// in a single-element array.
///
/// - Parameters:
///   - content: The content view.
///   - context: The rendering context.
/// - Returns: An array of ``ChildView``.
@MainActor
func resolveChildViews<V: View>(from content: V, context: RenderContext) -> [ChildView] {
    if let provider = content as? ChildViewProvider {
        return provider.childViews(context: context)
    }
    return [ChildView(content)]
}
