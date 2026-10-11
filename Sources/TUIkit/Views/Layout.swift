//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Layout.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

// MARK: - Proposed View Size

/// A proposal for the size of a view.
///
/// Matches SwiftUI's shape: `nil` components ask for the ideal size.
/// The renderer quantizes accepted proposals to whole cells through
/// `TerminalGeometry`.
public struct ProposedViewSize: Equatable, Sendable {
    /// The proposed width, or `nil` for the ideal width.
    public var width: CGFloat?

    /// The proposed height, or `nil` for the ideal height.
    public var height: CGFloat?

    /// Creates a proposal from optional dimensions.
    public init(width: CGFloat?, height: CGFloat?) {
        self.width = width
        self.height = height
    }

    /// Creates a proposal from a concrete size.
    public init(_ size: CGSize) {
        self.init(width: size.width, height: size.height)
    }

    /// The proposal that asks for the ideal size in both dimensions.
    public static let unspecified = Self(width: nil, height: nil)

    /// The proposal for zero size.
    public static let zero = Self(width: 0, height: 0)

    /// The proposal for the maximum size.
    public static let infinity = Self(width: .infinity, height: .infinity)
}

// MARK: - Layout Subview

/// A proxy for one child view of a custom layout.
///
/// Use the proxy to measure the child and to place it inside the
/// layout's bounds. Placement coordinates quantize to whole cells.
public struct LayoutSubview {
    /// Measures the child under the given proposal.
    let measureChild: (ProposedViewSize) -> CGSize

    /// Records the child's placement.
    let placeChild: (CGPoint, ProposedViewSize) -> Void

    /// Returns the size the child needs under the given proposal.
    ///
    /// - Parameter proposal: The size proposal for the child.
    /// - Returns: The child's size in cells.
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        measureChild(proposal)
    }

    /// Places the child at a position with a sizing proposal.
    ///
    /// The terminal adaptation anchors placements at the top-leading
    /// corner; positions quantize to whole cells.
    ///
    /// - Parameters:
    ///   - position: The top-leading position inside the layout bounds.
    ///   - proposal: The size proposal the child renders with.
    public func place(at position: CGPoint, proposal: ProposedViewSize) {
        placeChild(position, proposal)
    }
}

/// The collection of subview proxies handed to a custom layout.
public struct LayoutSubviews: RandomAccessCollection {
    /// The wrapped proxies.
    let subviews: [LayoutSubview]

    public var startIndex: Int { subviews.startIndex }
    public var endIndex: Int { subviews.endIndex }

    public subscript(position: Int) -> LayoutSubview {
        subviews[position]
    }
}

// MARK: - Layout Protocol

/// A type that defines the geometry of a collection of views.
///
/// Terminal adaptation of SwiftUI's `Layout`: implement
/// ``sizeThatFits(proposal:subviews:cache:)`` and
/// ``placeSubviews(in:proposal:subviews:cache:)``, then apply the layout
/// like a container view:
///
/// ```swift
/// struct Columns: Layout { … }
///
/// Columns {
///     Text("left")
///     Text("right")
/// }
/// ```
@MainActor
public protocol Layout {
    /// Cached values shared between sizing and placement.
    associatedtype Cache = Void

    /// A collection of subview proxies.
    typealias Subviews = LayoutSubviews

    /// Creates the layout's cache.
    ///
    /// - Parameter subviews: The layout's subview proxies.
    func makeCache(subviews: Subviews) -> Cache

    /// Returns the size the layout container needs.
    ///
    /// - Parameters:
    ///   - proposal: The size proposed to the container.
    ///   - subviews: The subview proxies to measure.
    ///   - cache: The layout's cache.
    /// - Returns: The container size in cells.
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize

    /// Places the subviews inside the container bounds.
    ///
    /// - Parameters:
    ///   - bounds: The container's bounds in cells (origin at zero).
    ///   - proposal: The size proposed to the container.
    ///   - subviews: The subview proxies to place.
    ///   - cache: The layout's cache.
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    )
}

extension Layout where Cache == Void {
    /// Default: layouts without shared state need no cache.
    public func makeCache(subviews: Subviews) {
        ()
    }
}

extension Layout {
    /// Applies the layout to the given content, like a container view.
    ///
    /// - Parameter content: The children to lay out.
    /// - Returns: A view arranging the children with this layout.
    public func callAsFunction<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        LayoutHostView(layout: self, content: content())
    }
}

// MARK: - AnyLayout

/// A type-erased instance of the layout protocol.
///
/// Use `AnyLayout` to switch between layouts while preserving the
/// container's position in the view hierarchy:
///
/// ```swift
/// let layout: AnyLayout = compact ? AnyLayout(Rows()) : AnyLayout(Columns())
/// layout { content }
/// ```
public struct AnyLayout: Layout {
    public typealias Cache = Any

    /// Erased cache factory.
    private let makeCacheErased: (Subviews) -> Any

    /// Erased sizing step.
    private let sizeThatFitsErased: (ProposedViewSize, Subviews, inout Any) -> CGSize

    /// Erased placement step.
    private let placeSubviewsErased: (CGRect, ProposedViewSize, Subviews, inout Any) -> Void

    /// Creates a type-erased layout wrapping the given instance.
    ///
    /// - Parameter layout: The layout to erase.
    public init<L: Layout>(_ layout: L) {
        self.makeCacheErased = { subviews in
            layout.makeCache(subviews: subviews)
        }
        self.sizeThatFitsErased = { proposal, subviews, cache in
            guard var typed = cache as? L.Cache else {
                var fresh = layout.makeCache(subviews: subviews)
                let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &fresh)
                cache = fresh
                return size
            }
            let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &typed)
            cache = typed
            return size
        }
        self.placeSubviewsErased = { bounds, proposal, subviews, cache in
            guard var typed = cache as? L.Cache else { return }
            layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &typed)
            cache = typed
        }
    }

    public func makeCache(subviews: Subviews) -> Any {
        makeCacheErased(subviews)
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Any
    ) -> CGSize {
        sizeThatFitsErased(proposal, subviews, &cache)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Any
    ) {
        placeSubviewsErased(bounds, proposal, subviews, &cache)
    }
}

// MARK: - Placement Store

/// One recorded placement per placed child of a custom layout.
private final class LayoutPlacementStore {
    /// Recorded placements keyed by child index.
    var placements: [Int: (position: CGPoint, proposal: ProposedViewSize)] = [:]
}

// MARK: - Layout Host

/// Renders a custom layout's children at their placed positions.
struct LayoutHostView<L: Layout, Content: View>: View {
    /// The layout arranging the children.
    let layout: L

    /// The children to arrange.
    let content: Content

    /// Never called — rendering is handled by `Renderable` conformance.
    var body: Never {
        fatalError("LayoutHostView renders via Renderable")
    }
}

extension LayoutHostView: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let children = resolveChildViews(from: content, context: context)
        guard !children.isEmpty else { return FrameBuffer() }

        let store = LayoutPlacementStore()

        func quantized(_ proposal: ProposedViewSize) -> ProposedSize {
            ProposedSize(
                width: proposal.width.map { max(0, TerminalGeometry.cells($0)) },
                height: proposal.height.map { max(0, TerminalGeometry.cells($0)) }
            )
        }

        let proxies = children.enumerated().map { index, child in
            LayoutSubview(
                measureChild: { proposal in
                    let size = child.measure(proposal: quantized(proposal), context: context)
                    return CGSize(width: CGFloat(size.width), height: CGFloat(size.height))
                },
                placeChild: { position, proposal in
                    store.placements[index] = (position, proposal)
                }
            )
        }
        let subviews = LayoutSubviews(subviews: proxies)

        var cache = layout.makeCache(subviews: subviews)
        let proposal = ProposedViewSize(
            width: CGFloat(context.availableWidth),
            height: CGFloat(context.availableHeight)
        )
        let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
        let containerWidth = min(max(0, TerminalGeometry.cells(size.width)), context.availableWidth)
        let containerHeight = min(max(0, TerminalGeometry.cells(size.height)), context.availableHeight)

        let bounds = CGRect(
            origin: .zero,
            size: CGSize(width: CGFloat(containerWidth), height: CGFloat(containerHeight))
        )
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)

        var result = FrameBuffer(
            lines: Array(repeating: "", count: containerHeight),
            width: containerWidth
        )
        for (index, child) in children.enumerated() {
            guard let placement = store.placements[index] else { continue }
            let childProposal = quantized(placement.proposal)
            let measured = child.measure(proposal: childProposal, context: context)
            let buffer = child.render(
                width: childProposal.width ?? measured.width,
                height: childProposal.height ?? measured.height,
                context: context
            )
            result = result.composited(
                with: buffer,
                at: (
                    x: TerminalGeometry.alignmentOffset(placement.position.x),
                    y: TerminalGeometry.alignmentOffset(placement.position.y)
                )
            )
        }
        return result
    }
}
