//
//  ViewRenderer.swift
//  TUIKit
//
//  Renders Views to terminal output via FrameBuffer.
//

import Foundation

/// Renders Views to terminal output.
///
/// The `ViewRenderer` uses a two-pass approach:
/// 1. Render the entire view tree into a `FrameBuffer`
/// 2. Flush the buffer to the terminal at the correct position
public final class ViewRenderer {
    /// The terminal to render to.
    private let terminal: Terminal

    /// Creates a new ViewRenderer.
    ///
    /// - Parameter terminal: The target terminal.
    public init(terminal: Terminal = .shared) {
        self.terminal = terminal
    }

    /// Renders a view to the terminal.
    ///
    /// - Parameters:
    ///   - view: The view to render.
    ///   - row: The starting row (1-based, default: 1).
    ///   - column: The starting column (1-based, default: 1).
    public func render<V: View>(_ view: V, atRow row: Int = 1, column: Int = 1) {
        let context = RenderContext(terminal: terminal)
        let buffer = renderToBuffer(view, context: context)
        flush(buffer, atRow: row, column: column)
    }

    /// Flushes a FrameBuffer to the terminal at the specified position.
    private func flush(_ buffer: FrameBuffer, atRow row: Int, column: Int) {
        for (index, line) in buffer.lines.enumerated() {
            terminal.moveCursor(toRow: row + index, column: column)
            terminal.write(line)
        }
    }
}

// MARK: - Child Info

/// Describes a child view within a stack for layout purposes.
struct ChildInfo {
    /// The rendered buffer of this child (nil for spacers, computed later).
    let buffer: FrameBuffer?

    /// Whether this child is a Spacer.
    let isSpacer: Bool

    /// The minimum length of this spacer (only relevant if isSpacer is true).
    let spacerMinLength: Int?
}

// MARK: - Child Info Provider

/// Internal protocol that allows stack containers to extract individual
/// child info from their content (which is typically a TupleView).
protocol ChildInfoProvider {
    /// Returns an array of ChildInfo, one per child view.
    func childInfos(context: RenderContext) -> [ChildInfo]
}

/// Creates a ChildInfo for a single view.
func makeChildInfo<V: View>(for view: V, context: RenderContext) -> ChildInfo {
    if let spacer = view as? Spacer {
        return ChildInfo(buffer: nil, isSpacer: true, spacerMinLength: spacer.minLength)
    }
    return ChildInfo(
        buffer: renderToBuffer(view, context: context),
        isSpacer: false,
        spacerMinLength: nil
    )
}

// MARK: - Text Rendering

extension Text: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(text: ANSIRenderer.render(content, with: style))
    }
}

// MARK: - EmptyView Rendering

extension EmptyView: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer()
    }
}

// MARK: - Spacer Rendering

extension Spacer: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Standalone spacer (outside a stack): render as empty lines
        let count = minLength ?? 1
        return FrameBuffer(emptyWithHeight: count)
    }
}

// MARK: - Divider Rendering

extension Divider: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let line = String(repeating: character, count: context.availableWidth)
        return FrameBuffer(text: line)
    }
}

// MARK: - VStack Rendering

extension VStack: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let infos = resolveChildInfos(from: content, context: context)

        // Count spacers and measure fixed children
        let spacerCount = infos.filter(\.isSpacer).count
        let fixedHeight = infos.compactMap(\.buffer).reduce(0) { $0 + $1.height }
        let totalSpacing = max(0, infos.count - 1) * spacing

        let availableForSpacers = max(0, context.availableHeight - fixedHeight - totalSpacing)
        let spacerHeight = spacerCount > 0 ? availableForSpacers / spacerCount : 0

        // Calculate max width for alignment
        let maxWidth = infos.compactMap(\.buffer).map(\.width).max() ?? 0

        var result = FrameBuffer()
        for (index, info) in infos.enumerated() {
            let spacingToApply = index > 0 ? spacing : 0
            if info.isSpacer {
                let height = max(info.spacerMinLength ?? 0, spacerHeight)
                result.appendVertically(FrameBuffer(emptyWithHeight: height), spacing: spacingToApply)
            } else if let buffer = info.buffer {
                // Apply horizontal alignment
                let alignedBuffer = alignBuffer(buffer, toWidth: maxWidth, alignment: alignment)
                result.appendVertically(alignedBuffer, spacing: spacingToApply)
            }
        }
        return result
    }
    
    /// Aligns a buffer horizontally within the given width.
    private func alignBuffer(_ buffer: FrameBuffer, toWidth width: Int, alignment: HorizontalAlignment) -> FrameBuffer {
        guard buffer.width < width else { return buffer }
        
        var alignedLines: [String] = []
        
        for line in buffer.lines {
            let lineWidth = line.strippedLength
            let linePadding = width - lineWidth
            
            switch alignment {
            case .leading:
                // Pad on right
                alignedLines.append(line + String(repeating: " ", count: linePadding))
            case .center:
                // Pad on both sides
                let leftPad = linePadding / 2
                let rightPad = linePadding - leftPad
                alignedLines.append(String(repeating: " ", count: leftPad) + line + String(repeating: " ", count: rightPad))
            case .trailing:
                // Pad on left
                alignedLines.append(String(repeating: " ", count: linePadding) + line)
            }
        }
        
        return FrameBuffer(lines: alignedLines)
    }
}

// MARK: - HStack Rendering

extension HStack: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let infos = resolveChildInfos(from: content, context: context)

        // Count spacers and measure fixed children
        let spacerCount = infos.filter(\.isSpacer).count
        let fixedWidth = infos.compactMap(\.buffer).reduce(0) { $0 + $1.width }
        let totalSpacing = max(0, infos.count - 1) * spacing

        let availableForSpacers = max(0, context.availableWidth - fixedWidth - totalSpacing)
        let spacerWidth = spacerCount > 0 ? availableForSpacers / spacerCount : 0

        var result = FrameBuffer()
        for (index, info) in infos.enumerated() {
            let spacingToApply = index > 0 ? spacing : 0
            if info.isSpacer {
                let width = max(info.spacerMinLength ?? 0, spacerWidth)
                let maxHeight = infos.compactMap(\.buffer).map(\.height).max() ?? 1
                let spacerBuffer = FrameBuffer(lines: Array(
                    repeating: String(repeating: " ", count: width),
                    count: maxHeight
                ))
                result.appendHorizontally(spacerBuffer, spacing: spacingToApply)
            } else if let buffer = info.buffer {
                result.appendHorizontally(buffer, spacing: spacingToApply)
            }
        }
        return result
    }
}

// MARK: - ZStack Rendering

extension ZStack: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let infos = resolveChildInfos(from: content, context: context)
        var result = FrameBuffer()
        for info in infos {
            if let buffer = info.buffer {
                result.overlay(buffer)
            }
        }
        return result
    }
}

// MARK: - TupleView Rendering + ChildInfoProvider

extension TupleView2: Renderable, ChildInfoProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        [
            makeChildInfo(for: value.0, context: context),
            makeChildInfo(for: value.1, context: context),
        ]
    }
}

extension TupleView3: Renderable, ChildInfoProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        [
            makeChildInfo(for: value.0, context: context),
            makeChildInfo(for: value.1, context: context),
            makeChildInfo(for: value.2, context: context),
        ]
    }
}

extension TupleView4: Renderable, ChildInfoProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        [
            makeChildInfo(for: value.0, context: context),
            makeChildInfo(for: value.1, context: context),
            makeChildInfo(for: value.2, context: context),
            makeChildInfo(for: value.3, context: context),
        ]
    }
}

extension TupleView5: Renderable, ChildInfoProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        [
            makeChildInfo(for: value.0, context: context),
            makeChildInfo(for: value.1, context: context),
            makeChildInfo(for: value.2, context: context),
            makeChildInfo(for: value.3, context: context),
            makeChildInfo(for: value.4, context: context),
        ]
    }
}

extension TupleView6: Renderable, ChildInfoProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        [
            makeChildInfo(for: value.0, context: context),
            makeChildInfo(for: value.1, context: context),
            makeChildInfo(for: value.2, context: context),
            makeChildInfo(for: value.3, context: context),
            makeChildInfo(for: value.4, context: context),
            makeChildInfo(for: value.5, context: context),
        ]
    }
}

extension TupleView7: Renderable, ChildInfoProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        [
            makeChildInfo(for: value.0, context: context),
            makeChildInfo(for: value.1, context: context),
            makeChildInfo(for: value.2, context: context),
            makeChildInfo(for: value.3, context: context),
            makeChildInfo(for: value.4, context: context),
            makeChildInfo(for: value.5, context: context),
            makeChildInfo(for: value.6, context: context),
        ]
    }
}

extension TupleView8: Renderable, ChildInfoProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        [
            makeChildInfo(for: value.0, context: context),
            makeChildInfo(for: value.1, context: context),
            makeChildInfo(for: value.2, context: context),
            makeChildInfo(for: value.3, context: context),
            makeChildInfo(for: value.4, context: context),
            makeChildInfo(for: value.5, context: context),
            makeChildInfo(for: value.6, context: context),
            makeChildInfo(for: value.7, context: context),
        ]
    }
}

extension TupleView9: Renderable, ChildInfoProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        [
            makeChildInfo(for: value.0, context: context),
            makeChildInfo(for: value.1, context: context),
            makeChildInfo(for: value.2, context: context),
            makeChildInfo(for: value.3, context: context),
            makeChildInfo(for: value.4, context: context),
            makeChildInfo(for: value.5, context: context),
            makeChildInfo(for: value.6, context: context),
            makeChildInfo(for: value.7, context: context),
            makeChildInfo(for: value.8, context: context),
        ]
    }
}

extension TupleView10: Renderable, ChildInfoProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        [
            makeChildInfo(for: value.0, context: context),
            makeChildInfo(for: value.1, context: context),
            makeChildInfo(for: value.2, context: context),
            makeChildInfo(for: value.3, context: context),
            makeChildInfo(for: value.4, context: context),
            makeChildInfo(for: value.5, context: context),
            makeChildInfo(for: value.6, context: context),
            makeChildInfo(for: value.7, context: context),
            makeChildInfo(for: value.8, context: context),
            makeChildInfo(for: value.9, context: context),
        ]
    }
}

// MARK: - ConditionalView Rendering

extension ConditionalView: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        switch self {
        case .trueContent(let content):
            return TUIKit.renderToBuffer(content, context: context)
        case .falseContent(let content):
            return TUIKit.renderToBuffer(content, context: context)
        }
    }
}

// MARK: - ViewArray Rendering

extension ViewArray: Renderable, ChildInfoProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        elements.map { makeChildInfo(for: $0, context: context) }
    }
}

// MARK: - Child Info Resolution

/// Resolves child infos from a view's content.
///
/// If the content conforms to `ChildInfoProvider` (e.g. TupleViews),
/// it returns individual child infos. Otherwise it returns the content
/// as a single-element array.
///
/// - Parameters:
///   - content: The content view.
///   - context: The rendering context.
/// - Returns: An array of ChildInfo.
func resolveChildInfos<V: View>(from content: V, context: RenderContext) -> [ChildInfo] {
    if let provider = content as? ChildInfoProvider {
        return provider.childInfos(context: context)
    }
    return [makeChildInfo(for: content, context: context)]
}
