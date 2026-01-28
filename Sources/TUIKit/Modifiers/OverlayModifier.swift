//
//  OverlayModifier.swift
//  TUIKit
//
//  A modifier that renders an overlay on top of the base view.
//

/// Internal modifier that layers an overlay view on top of the base content.
///
/// The overlay is rendered on top of the base content. Both views are rendered
/// to their natural size, and the overlay is positioned according to the
/// specified alignment within the base content's bounds.
public struct OverlayModifier<Base: View, Overlay: View>: View {
    /// The base content.
    let base: Base

    /// The overlay content.
    let overlay: Overlay

    /// The alignment of the overlay within the base bounds.
    let alignment: Alignment

    public var body: Never {
        fatalError("OverlayModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension OverlayModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Render both contents
        let baseBuffer = TUIKit.renderToBuffer(base, context: context)
        let overlayBuffer = TUIKit.renderToBuffer(overlay, context: context)

        guard !baseBuffer.isEmpty else {
            return overlayBuffer
        }

        guard !overlayBuffer.isEmpty else {
            return baseBuffer
        }

        // Calculate the position of the overlay based on alignment
        let baseWidth = baseBuffer.width
        let baseHeight = baseBuffer.height
        let overlayWidth = overlayBuffer.width
        let overlayHeight = overlayBuffer.height

        // Calculate horizontal position
        let xOffset: Int
        switch alignment.horizontal {
        case .leading:
            xOffset = 0
        case .center:
            xOffset = max(0, (baseWidth - overlayWidth) / 2)
        case .trailing:
            xOffset = max(0, baseWidth - overlayWidth)
        }

        // Calculate vertical position
        let yOffset: Int
        switch alignment.vertical {
        case .top:
            yOffset = 0
        case .center:
            yOffset = max(0, (baseHeight - overlayHeight) / 2)
        case .bottom:
            yOffset = max(0, baseHeight - overlayHeight)
        }

        // Composite the overlay onto the base
        return baseBuffer.composited(with: overlayBuffer, at: (x: xOffset, y: yOffset))
    }
}

// MARK: - View Extension

extension View {
    /// Layers the specified view on top of this view.
    ///
    /// The overlay is positioned according to the specified alignment
    /// within the bounds of the base view.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Background content here")
    ///     .overlay(alignment: .center) {
    ///         Text("Centered overlay")
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - alignment: The alignment of the overlay (default: .center).
    ///   - content: The overlay content.
    /// - Returns: A view with the overlay applied.
    public func overlay<Overlay: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Overlay
    ) -> some View {
        OverlayModifier(base: self, overlay: content(), alignment: alignment)
    }
}
