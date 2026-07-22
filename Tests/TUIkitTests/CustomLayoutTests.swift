//  🖥️ TUIKit — Terminal UI Kit for Swift
//  CustomLayoutTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

@MainActor
@Suite("Custom Layouts")
struct CustomLayoutTests {

    /// Creates an isolated render context.
    private func testContext(width: Int, height: Int) -> RenderContext {
        RenderContext(
            availableWidth: width,
            availableHeight: height,
            tuiContext: TUIContext()
        )
    }

    /// Stacks children diagonally: each child moves one cell right and down.
    struct DiagonalLayout: Layout {
        func sizeThatFits(
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) -> CGSize {
            var width: CGFloat = 0
            var height: CGFloat = 0
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                width = max(width, CGFloat(index) + size.width)
                height = max(height, CGFloat(index) + size.height)
            }
            return CGSize(width: width, height: height)
        }

        func placeSubviews(
            in bounds: CGRect,
            proposal: ProposedViewSize,
            subviews: Subviews,
            cache: inout Void
        ) {
            for (index, subview) in subviews.enumerated() {
                subview.place(
                    at: CGPoint(x: CGFloat(index), y: CGFloat(index)),
                    proposal: .unspecified
                )
            }
        }
    }

    @Test("A custom layout places children at its computed positions")
    func customLayoutPlacesChildren() {
        let layout = DiagonalLayout()
        let view = layout {
            Text("a")
            Text("b")
            Text("c")
        }

        let rows = renderToBuffer(view, context: testContext(width: 10, height: 5))
            .lines.map(\.stripped)

        #expect(rows.count == 3)
        #expect(rows[0].hasPrefix("a"))
        #expect(rows[1].hasPrefix(" b"))
        #expect(rows[2].hasPrefix("  c"))
    }

    @Test("AnyLayout delegates to the wrapped layout")
    func anyLayoutDelegates() {
        let layout = AnyLayout(DiagonalLayout())
        let view = layout {
            Text("x")
            Text("y")
        }

        let rows = renderToBuffer(view, context: testContext(width: 10, height: 4))
            .lines.map(\.stripped)

        #expect(rows.count == 2)
        #expect(rows[0].hasPrefix("x"))
        #expect(rows[1].hasPrefix(" y"))
    }
}
