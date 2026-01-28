//
//  FrameModifier.swift
//  SwiftTUI
//
//  The .frame() modifier for setting explicit size constraints.
//

/// A modifier that constrains a view to a specific width and/or height.
///
/// Content is aligned within the frame according to the specified alignment.
public struct FrameModifier: TViewModifier {
    /// The desired width (nil means intrinsic width).
    public let width: Int?

    /// The desired height (nil means intrinsic height).
    public let height: Int?

    /// The alignment of the content within the frame.
    public let alignment: Alignment

    public func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer {
        let targetWidth = width ?? buffer.width
        let targetHeight = height ?? buffer.height

        var result: [String] = []

        // Calculate vertical offset for alignment
        let verticalOffset: Int
        switch alignment.vertical {
        case .top:
            verticalOffset = 0
        case .center:
            verticalOffset = max(0, (targetHeight - buffer.height) / 2)
        case .bottom:
            verticalOffset = max(0, targetHeight - buffer.height)
        }

        for row in 0..<targetHeight {
            let contentRow = row - verticalOffset
            let line: String
            if contentRow >= 0 && contentRow < buffer.lines.count {
                line = buffer.lines[contentRow]
            } else {
                line = ""
            }

            // Align horizontally within the frame
            let aligned = alignHorizontally(
                line,
                toWidth: targetWidth,
                alignment: alignment.horizontal
            )
            result.append(aligned)
        }

        return FrameBuffer(lines: result)
    }

    /// Aligns a single line within the given width.
    private func alignHorizontally(
        _ line: String,
        toWidth targetWidth: Int,
        alignment: HorizontalAlignment
    ) -> String {
        let visibleWidth = line.strippedLength

        if visibleWidth >= targetWidth {
            return line
        }

        let padding = targetWidth - visibleWidth

        switch alignment {
        case .leading:
            return line + String(repeating: " ", count: padding)
        case .center:
            let left = padding / 2
            let right = padding - left
            return String(repeating: " ", count: left) + line + String(repeating: " ", count: right)
        case .trailing:
            return String(repeating: " ", count: padding) + line
        }
    }
}

// MARK: - TView Extension

extension TView {
    /// Sets the frame size of this view.
    ///
    /// The content is aligned within the frame according to the specified alignment.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Hello")
    ///     .frame(width: 20, alignment: .center)
    /// ```
    ///
    /// - Parameters:
    ///   - width: The desired width in characters (nil preserves intrinsic width).
    ///   - height: The desired height in lines (nil preserves intrinsic height).
    ///   - alignment: The alignment within the frame (default: .topLeading).
    /// - Returns: A view constrained to the specified frame.
    public func frame(
        width: Int? = nil,
        height: Int? = nil,
        alignment: Alignment = .topLeading
    ) -> ModifiedView<Self, FrameModifier> {
        modifier(FrameModifier(width: width, height: height, alignment: alignment))
    }
}
