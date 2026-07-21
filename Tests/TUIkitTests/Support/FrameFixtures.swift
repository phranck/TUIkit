//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FrameFixtures.swift
//
//  License: MIT

@testable import TUIkit

// MARK: - Growable Header

/// Mutable header size shared between a test and its app fixture.
///
/// Growing `lineCount` between frames invalidates the header height
/// estimate, forcing the next frame through the header-correction pass.
@MainActor
final class GrowableHeaderModel {
    var lineCount = 1
}

/// Renders `lineCount` header lines from a ``GrowableHeaderModel``.
///
/// With the standard 40×24 ``FrameHarness``: frame 1 commits a header of
/// height 2 (one line + divider). After `lineCount = 3`, frame 2 estimates
/// height 2, renders the main pass at content height 22, discovers actual
/// height 4, and re-renders the correction pass at content height 20.
struct GrowingHeader: View {
    let model: GrowableHeaderModel

    var body: some View {
        VStack {
            ForEach(Array(0..<model.lineCount), id: \.self) { line in
                Text("Header line \(line)")
            }
        }
    }
}

// MARK: - Height Gate

/// Renders `content` only when the available height is at least `threshold`.
///
/// Records nothing and has no effects of its own; used to make a subtree
/// exist in one pass of a frame but not in another (measure vs. main, or
/// main vs. correction).
struct HeightGate<Content: View>: View, Renderable {
    let threshold: Int
    let content: Content

    var body: Never {
        fatalError("HeightGate renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        guard context.availableHeight >= threshold else {
            return FrameBuffer(text: "below-gate")
        }
        return TUIkit.renderToBuffer(content, context: context)
    }
}
