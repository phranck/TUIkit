//  🖥️ TUIKit — Terminal UI Kit for Swift
//  BorderRendererTests.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

import Testing

@testable import TUIkit

// MARK: - Standard Style Tests

@Suite("BorderRenderer Standard Style Tests")
struct BorderRendererStandardTests {

    @Test("standardTopBorder uses correct corner characters")
    func topBorderCorners() {
        let result = BorderRenderer.standardTopBorder(
            style: .line,
            innerWidth: 5,
            color: .white
        )
        let stripped = result.stripped
        #expect(stripped.hasPrefix("┌"))
        #expect(stripped.hasSuffix("┐"))
    }

    @Test("standardTopBorder has correct total width")
    func topBorderWidth() {
        let result = BorderRenderer.standardTopBorder(
            style: .line,
            innerWidth: 10,
            color: .white
        )
        // corners (2) + inner horizontal (10) = 12
        #expect(result.stripped.count == 12)
    }

    @Test("standardTopBorder with title embeds title text")
    func topBorderWithTitle() {
        let result = BorderRenderer.standardTopBorder(
            style: .line,
            innerWidth: 20,
            color: .white,
            title: "Title",
            titleColor: .green
        )
        let stripped = result.stripped
        #expect(stripped.contains("Title"))
        #expect(stripped.hasPrefix("┌"))
        #expect(stripped.hasSuffix("┐"))
    }

    @Test("standardBottomBorder uses correct corner characters")
    func bottomBorderCorners() {
        let result = BorderRenderer.standardBottomBorder(
            style: .line,
            innerWidth: 5,
            color: .white
        )
        let stripped = result.stripped
        #expect(stripped.hasPrefix("└"))
        #expect(stripped.hasSuffix("┘"))
    }

    @Test("standardBottomBorder has correct total width")
    func bottomBorderWidth() {
        let result = BorderRenderer.standardBottomBorder(
            style: .line,
            innerWidth: 8,
            color: .white
        )
        #expect(result.stripped.count == 10) // 8 + 2 corners
    }

    @Test("standardDivider uses T-junction characters")
    func dividerTJunctions() {
        let result = BorderRenderer.standardDivider(
            style: .line,
            innerWidth: 5,
            color: .white
        )
        let stripped = result.stripped
        #expect(stripped.hasPrefix("├"))
        #expect(stripped.hasSuffix("┤"))
    }

    @Test("standardDivider has correct total width")
    func dividerWidth() {
        let result = BorderRenderer.standardDivider(
            style: .line,
            innerWidth: 6,
            color: .white
        )
        #expect(result.stripped.count == 8)
    }

    @Test("standardContentLine wraps content with vertical borders")
    func contentLineVerticals() {
        let result = BorderRenderer.standardContentLine(
            content: "Hello",
            innerWidth: 10,
            style: .line,
            color: .white
        )
        let stripped = result.stripped
        #expect(stripped.hasPrefix("│"))
        #expect(stripped.hasSuffix("│"))
    }

    @Test("standardContentLine pads content to innerWidth")
    func contentLinePadding() {
        let result = BorderRenderer.standardContentLine(
            content: "Hi",
            innerWidth: 10,
            style: .line,
            color: .white
        )
        let stripped = result.stripped
        // │ + padded content (10 chars) + │ = 12
        #expect(stripped.count == 12)
    }

    @Test("standardContentLine with zero innerWidth")
    func contentLineZeroWidth() {
        let result = BorderRenderer.standardContentLine(
            content: "",
            innerWidth: 0,
            style: .line,
            color: .white
        )
        let stripped = result.stripped
        // Just two vertical borders
        #expect(stripped.hasPrefix("│"))
        #expect(stripped.hasSuffix("│"))
    }

    @Test("standardContentLine with backgroundColor applies ANSI background")
    func contentLineBackground() {
        let result = BorderRenderer.standardContentLine(
            content: "Test",
            innerWidth: 10,
            style: .line,
            color: .white,
            backgroundColor: .blue
        )
        // Should contain ANSI blue background code (44)
        #expect(result.contains("\u{1B}[44m"))
    }

    // MARK: Double Line Style

    @Test("standardTopBorder with doubleLine uses double corners")
    func doubleLineTopBorder() {
        let result = BorderRenderer.standardTopBorder(
            style: .doubleLine,
            innerWidth: 5,
            color: .white
        )
        let stripped = result.stripped
        #expect(stripped.hasPrefix("╔"))
        #expect(stripped.hasSuffix("╗"))
    }

    @Test("standardDivider with doubleLine uses double T-junctions")
    func doubleLineDivider() {
        let result = BorderRenderer.standardDivider(
            style: .doubleLine,
            innerWidth: 5,
            color: .white
        )
        let stripped = result.stripped
        #expect(stripped.hasPrefix("╠"))
        #expect(stripped.hasSuffix("╣"))
    }

    // MARK: Rounded Style

    @Test("standardTopBorder with rounded uses round corners")
    func roundedTopBorder() {
        let result = BorderRenderer.standardTopBorder(
            style: .rounded,
            innerWidth: 5,
            color: .white
        )
        let stripped = result.stripped
        #expect(stripped.hasPrefix("╭"))
        #expect(stripped.hasSuffix("╮"))
    }
}

// MARK: - Focus Indicator Tests

@Suite("BorderRenderer Focus Indicator Tests")
struct BorderRendererFocusIndicatorTests {

    @Test("Top border with focus indicator contains dot character")
    func topBorderWithIndicator() {
        let result = BorderRenderer.standardTopBorder(
            style: .rounded,
            innerWidth: 10,
            color: .white,
            focusIndicatorColor: .cyan
        )
        let stripped = result.stripped
        #expect(stripped.contains("●"), "Should contain focus indicator character")
        #expect(stripped.hasPrefix("╭"), "Should start with corner")
        #expect(stripped.hasSuffix("╮"), "Should end with corner")
    }

    @Test("Top border without indicator has no dot")
    func topBorderWithoutIndicator() {
        let result = BorderRenderer.standardTopBorder(
            style: .rounded,
            innerWidth: 10,
            color: .white
        )
        let stripped = result.stripped
        #expect(!stripped.contains("●"), "Should not contain focus indicator")
    }

    @Test("Focus indicator preserves total visual width")
    func indicatorPreservesWidth() {
        let withIndicator = BorderRenderer.standardTopBorder(
            style: .line,
            innerWidth: 10,
            color: .white,
            focusIndicatorColor: .cyan
        )
        let without = BorderRenderer.standardTopBorder(
            style: .line,
            innerWidth: 10,
            color: .white
        )
        // Both should have the same visual width (● replaces one ─)
        #expect(withIndicator.stripped.count == without.stripped.count)
    }

    @Test("Title border with focus indicator contains both")
    func titleBorderWithIndicator() {
        let result = BorderRenderer.standardTopBorder(
            style: .rounded,
            innerWidth: 20,
            color: .white,
            title: "Panel",
            titleColor: .cyan,
            focusIndicatorColor: .green
        )
        let stripped = result.stripped
        #expect(stripped.contains("●"), "Should contain focus indicator")
        #expect(stripped.contains("Panel"), "Should contain title")
    }
}
