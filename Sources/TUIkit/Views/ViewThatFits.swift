//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewThatFits.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - View That Fits

/// A view that adapts to the available space by providing the first child
/// view that fits.
///
/// Declare candidates from largest to smallest; the first child whose
/// measured size fits the proposed space in the constrained axes renders.
/// When none fits, the last child renders:
///
/// ```swift
/// ViewThatFits {
///     Text("A verbose description of the state")
///     Text("Short state")
///     Text("S")
/// }
/// ```
public struct ViewThatFits<Content: View>: View {
    /// The axes the candidates must fit in.
    let axes: Axis.Set

    /// The candidate views, largest first.
    let content: Content

    /// Creates a view that adapts to the available space.
    ///
    /// - Parameters:
    ///   - axes: The axes the child views must fit in (default: both).
    ///   - content: The candidate views, ordered largest to smallest.
    public init(
        in axes: Axis.Set = [.horizontal, .vertical],
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.content = content()
    }

    /// Never called — rendering is handled by `Renderable` conformance.
    public var body: Never {
        fatalError("ViewThatFits renders via Renderable")
    }

    /// The probe extent used to discover a candidate's ideal size.
    ///
    /// Wide enough for any realistic terminal content while keeping
    /// measurement buffers bounded and deterministic on both platforms.
    static var idealProbeCells: Int { 1024 }
}

// MARK: - Rendering

extension ViewThatFits: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let children = resolveChildViews(from: content, context: context)
        guard !children.isEmpty else { return FrameBuffer() }

        // Measure against a generous probe in the constrained axes:
        // adaptive children (like truncating text) would otherwise shrink
        // to the proposal and always "fit". The ideal size decides whether
        // a candidate fits the actually available space.
        let probeWidth = axes.contains(.horizontal)
            ? max(context.availableWidth, Self.idealProbeCells)
            : context.availableWidth
        let probeHeight = axes.contains(.vertical)
            ? max(context.availableHeight, Self.idealProbeCells)
            : context.availableHeight
        var measureContext = context
        measureContext.availableWidth = probeWidth
        measureContext.availableHeight = probeHeight
        let proposal = ProposedSize(width: probeWidth, height: probeHeight)

        for child in children {
            let size = child.measure(proposal: proposal, context: measureContext)

            let fitsHorizontally = !axes.contains(.horizontal)
                || size.width <= context.availableWidth
            let fitsVertically = !axes.contains(.vertical)
                || size.height <= context.availableHeight

            if fitsHorizontally && fitsVertically {
                return child.render(width: size.width, height: size.height, context: context)
            }
        }

        // Nothing fits: fall back to the smallest (last) candidate,
        // clipped to the available space.
        let fallback = children[children.count - 1]
        let size = fallback.measure(proposal: proposal, context: measureContext)
        return fallback.render(
            width: min(size.width, context.availableWidth),
            height: min(size.height, context.availableHeight),
            context: context
        )
    }
}
