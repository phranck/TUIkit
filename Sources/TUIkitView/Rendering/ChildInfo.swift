//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ChildInfo.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - Child Info

/// A type-erased wrapper for a child view that enables two-pass layout.
///
/// This wrapper stores the view and allows measuring without rendering,
/// then rendering with a specific size allocation.
@MainActor
public struct ChildView {
    private let _measure: (ProposedSize, RenderContext) -> ViewSize
    private let _render: (Int, Int, RenderContext) -> FrameBuffer

    /// Whether this child is a Spacer.
    public let isSpacer: Bool

    /// The minimum length of this spacer (only relevant if isSpacer is true).
    public let spacerMinLength: Int?

    public init<V: View>(_ view: V) {
        if let spacer = view as? SpacerProtocol {
            self.isSpacer = true
            self.spacerMinLength = spacer.spacerMinLength
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

    /// Creates a child view wrapper with an explicit child index for identity propagation.
    ///
    /// Use this initializer when wrapping children from a `TupleView` or similar
    /// container so that each child receives a unique `ViewIdentity` during
    /// measure and render passes.
    ///
    /// - Parameters:
    ///   - view: The child view to wrap.
    ///   - childIndex: The positional index used for identity disambiguation.
    public init<V: View>(_ view: V, childIndex: Int) {
        if let spacer = view as? SpacerProtocol {
            self.isSpacer = true
            self.spacerMinLength = spacer.spacerMinLength
        } else {
            self.isSpacer = false
            self.spacerMinLength = nil
        }

        self._measure = { proposal, context in
            let childContext = context.withChildIdentity(type: V.self, index: childIndex)
            return measureChild(view, proposal: proposal, context: childContext)
        }
        self._render = { width, height, context in
            let childContext = context.withChildIdentity(type: V.self, index: childIndex)
            return renderChild(view, width: width, height: height, context: childContext)
        }
    }

    /// Measures this child view without rendering.
    public func measure(proposal: ProposedSize, context: RenderContext) -> ViewSize {
        _measure(proposal, context)
    }

    /// Renders this child view with the given size allocation.
    public func render(width: Int, height: Int, context: RenderContext) -> FrameBuffer {
        _render(width, height, context)
    }
}

/// Describes a child view within a stack for layout purposes.
public struct ChildInfo {
    /// The rendered buffer of this child (nil for spacers, computed later).
    public let buffer: FrameBuffer?

    /// Whether this child is a Spacer.
    public let isSpacer: Bool

    /// The minimum length of this spacer (only relevant if isSpacer is true).
    public let spacerMinLength: Int?

    /// The size this child needs (from sizeThatFits).
    /// Only available when using two-pass layout.
    public let size: ViewSize?

    /// Creates a new child info.
    public init(buffer: FrameBuffer?, isSpacer: Bool, spacerMinLength: Int?, size: ViewSize?) {
        self.buffer = buffer
        self.isSpacer = isSpacer
        self.spacerMinLength = spacerMinLength
        self.size = size
    }
}

// MARK: - Child Info Provider

/// Internal protocol that allows stack containers to extract individual
/// child info from their content (which is typically a TupleView).
@MainActor
public protocol ChildInfoProvider {
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
public protocol ChildViewProvider {
    /// Returns an array of type-erased child views for two-pass layout.
    ///
    /// - Parameter context: The rendering context (for child identity).
    /// - Returns: An array of ``ChildView`` wrappers.
    func childViews(context: RenderContext) -> [ChildView]
}

/// Creates a ChildInfo for a single view.
///
/// If the view conforms to ``SpacerProtocol``, the returned info marks it as such
/// with its minimum length. Otherwise the view is rendered into a
/// ``FrameBuffer`` via ``renderToBuffer(_:context:)``.
///
/// - Parameters:
///   - view: The child view.
///   - context: The rendering context.
/// - Returns: A ``ChildInfo`` describing the view.
@MainActor
public func makeChildInfo<V: View>(for view: V, context: RenderContext) -> ChildInfo {
    if let spacer = view as? SpacerProtocol {
        return ChildInfo(buffer: nil, isSpacer: true, spacerMinLength: spacer.spacerMinLength, size: nil)
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
public func measureChild<V: View>(_ view: V, proposal: ProposedSize, context: RenderContext) -> ViewSize {
    // Spacer is always flexible
    if let spacer = view as? SpacerProtocol {
        let min = spacer.spacerMinLength ?? 0
        return ViewSize(width: min, height: min, isWidthFlexible: true, isHeightFlexible: true)
    }

    // Use Layoutable if available (mark as measuring to suppress side-effects)
    if let layoutable = view as? Layoutable {
        var measureContext = context
        measureContext.isMeasuring = true
        return layoutable.sizeThatFits(proposal: proposal, context: measureContext)
    }

    // For composite views (Body != Never, NOT Renderable), traverse into
    // the body to find an inner Layoutable. This handles cases like
    // TextField<Text> whose body is _TextFieldCore<Text> which IS Layoutable.
    //
    // Skip Renderable views: their rendering logic (including environment
    // injection) lives in renderToBuffer, not in body. They fall through
    // to the render-to-measure fallback below, which runs the full pipeline.
    if !(view is Renderable), V.Body.self != Never.self {
        let body = StateRegistration.withHydration(context: context) {
            view.body
        }
        return measureChild(body, proposal: proposal, context: context)
    }

    // Fallback: render to measure (without side-effects)
    var measureContext = context
    measureContext.isMeasuring = true
    // Clear hasExplicitWidth so views report their natural (minimum) size
    // instead of expanding to fill the full available width.
    let wasExplicitWidth = measureContext.hasExplicitWidth
    measureContext.hasExplicitWidth = false
    if let width = proposal.width {
        measureContext.availableWidth = width
    }
    if let height = proposal.height {
        measureContext.availableHeight = height
    }
    let buffer = renderToBuffer(view, context: measureContext)
    // If the view had explicit width, report it as width-flexible so the
    // parent stack can distribute remaining space to it.
    if wasExplicitWidth {
        return ViewSize.flexibleWidth(minWidth: buffer.width, height: buffer.height)
    }
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
public func renderChild<V: View>(_ view: V, width: Int, height: Int, context: RenderContext) -> FrameBuffer {
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
public func resolveChildInfos<V: View>(from content: V, context: RenderContext) -> [ChildInfo] {
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
public func resolveChildViews<V: View>(from content: V, context: RenderContext) -> [ChildView] {
    if let provider = content as? ChildViewProvider {
        return provider.childViews(context: context)
    }
    return [ChildView(content)]
}
