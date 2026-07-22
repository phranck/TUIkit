//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AlignmentGuideTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

@MainActor
@Suite("Alignment Guides")
struct AlignmentGuideTests {

    /// Aligns one third into the available width.
    private enum OneThird: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context.width / 3
        }
    }

    // MARK: - Identity

    @Test("Built-in alignments equate by guide identity")
    func builtInAlignmentsEquate() {
        // swiftlint:disable:next identical_operands
        #expect(HorizontalAlignment.leading == .leading)
        #expect(HorizontalAlignment.leading != .center)
        #expect(VerticalAlignment.top != .bottom)
        #expect(HorizontalAlignment(OneThird.self) == HorizontalAlignment(OneThird.self))
        #expect(HorizontalAlignment(OneThird.self) != .center)
    }

    // MARK: - Built-In Offsets

    @Test("Built-in guides keep the established floor-based offsets")
    func builtInOffsets() {
        #expect(HorizontalAlignment.leading.cellOffset(childWidth: 3, containerWidth: 10) == 0)
        #expect(HorizontalAlignment.center.cellOffset(childWidth: 3, containerWidth: 10) == 3)
        #expect(HorizontalAlignment.trailing.cellOffset(childWidth: 3, containerWidth: 10) == 7)
        #expect(VerticalAlignment.center.cellOffset(childHeight: 1, containerHeight: 4) == 1)
        #expect(VerticalAlignment.bottom.cellOffset(childHeight: 2, containerHeight: 5) == 3)
    }

    @Test("Oversized children clamp to offset zero")
    func oversizedChildrenClamp() {
        #expect(HorizontalAlignment.center.cellOffset(childWidth: 12, containerWidth: 10) == 0)
        #expect(VerticalAlignment.bottom.cellOffset(childHeight: 9, containerHeight: 4) == 0)
    }

    // MARK: - Custom Guides

    @Test("Custom alignment guides resolve deterministically")
    func customGuideResolves() {
        let guide = HorizontalAlignment(OneThird.self)

        // container/3 - child/3 = (12 - 3) / 3 = 3
        #expect(guide.cellOffset(childWidth: 3, containerWidth: 12) == 3)
        // floor((10 - 4) / 3) = 2
        #expect(guide.cellOffset(childWidth: 4, containerWidth: 10) == 2)
    }

    // MARK: - Quantization Policy

    @Test("The quantization policy handles degenerate inputs deterministically")
    func quantizationPolicy() {
        #expect(TerminalGeometry.cells(2.5) == 3)
        #expect(TerminalGeometry.cells(-2.5) == -3)
        #expect(TerminalGeometry.cells(.infinity) == .max)
        #expect(TerminalGeometry.cells(CGFloat.nan) == 0)
        #expect(TerminalGeometry.alignmentOffset(2.5) == 2)
        #expect(TerminalGeometry.alignmentOffset(-0.5) == -1)
        #expect(TerminalGeometry.spacing(nil, default: 1) == 1)
        #expect(TerminalGeometry.spacing(-3, default: 1) == 0)
        #expect(TerminalGeometry.spacing(2.4, default: 1) == 2)
    }
}
