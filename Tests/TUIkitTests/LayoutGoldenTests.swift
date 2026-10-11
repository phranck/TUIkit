//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LayoutGoldenTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("Layout Golden Tests")
struct LayoutGoldenTests {

    /// Creates an isolated render context.
    private func testContext(width: Int, height: Int) -> RenderContext {
        RenderContext(
            availableWidth: width,
            availableHeight: height,
            tuiContext: TUIContext()
        )
    }

    /// Renders a view and returns the stripped output rows.
    private func rows(_ view: some View, width: Int, height: Int) -> [String] {
        renderToBuffer(view, context: testContext(width: width, height: height))
            .lines.map(\.stripped)
    }

    // MARK: - ZStack Alignment

    @Test("ZStack honors every corner alignment")
    func zstackCornerAlignments() {
        let base = Text("aaaa\naaaa\naaaa")

        let topLeading = rows(
            ZStack(alignment: .topLeading) { base; Text("X") },
            width: 10, height: 5
        )
        #expect(topLeading[0].hasPrefix("X"))

        let bottomTrailing = rows(
            ZStack(alignment: .bottomTrailing) { base; Text("X") },
            width: 10, height: 5
        )
        #expect(bottomTrailing[2].hasSuffix("X"))

        let center = rows(
            ZStack(alignment: .center) { base; Text("X") },
            width: 10, height: 5
        )
        #expect(center[1].contains("aXaa"))
    }

    // MARK: - Frame Alignment

    @Test("Fixed frames center their content by default like SwiftUI")
    func fixedFrameCentersByDefault() {
        let framed = rows(Text("ab").frame(width: 6, height: 3), width: 10, height: 5)

        #expect(framed.count == 3)
        #expect(framed[0].trimmingCharacters(in: .whitespaces).isEmpty)
        #expect(framed[1] == "  ab  ")
        #expect(framed[2].trimmingCharacters(in: .whitespaces).isEmpty)
    }

    @Test("Frame alignment places content at the requested corner")
    func frameAlignmentCorners() {
        let bottomTrailing = rows(
            Text("ab").frame(width: 6, height: 3, alignment: .bottomTrailing),
            width: 10, height: 5
        )
        #expect(bottomTrailing[2] == "    ab")

        let topLeading = rows(
            Text("ab").frame(width: 6, height: 3, alignment: .topLeading),
            width: 10, height: 5
        )
        #expect(topLeading[0] == "ab    ")
    }

    // MARK: - Nested Proposal Propagation

    @Test("Nested frames propagate reduced proposals to their children")
    func nestedProposalPropagation() {
        let nested = rows(
            VStack {
                Text("wide content here")
                    .frame(maxWidth: .infinity)
            }
            .frame(width: 8),
            width: 20, height: 4
        )

        // The inner infinity frame fills the outer 8-cell frame, not the
        // 20-cell terminal: every row stays within 8 cells.
        #expect(nested.allSatisfy { $0.count <= 8 })
    }

    @Test("Padding reduces the space proposed to flexible children")
    func paddingReducesProposals() {
        let padded = rows(
            Text("x")
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2),
            width: 12, height: 3
        )

        // 12 cells minus 2 padding per side leaves an 8-cell fill plus
        // the re-added padding spaces.
        #expect(padded.contains { $0.count == 12 })
    }
}
