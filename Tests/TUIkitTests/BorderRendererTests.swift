//
//  BorderRendererTests.swift
//  TUIkit
//
//  Tests for BorderRenderer: standard and block border rendering methods.
//

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
        // Should contain background ANSI code
        #expect(result.contains("\u{1B}["))
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

// MARK: - Block Style Tests

@Suite("BorderRenderer Block Style Tests")
struct BorderRendererBlockTests {

    @Test("blockTopBorder uses lower half block character")
    func blockTopBorderCharacter() {
        let result = BorderRenderer.blockTopBorder(
            innerWidth: 5,
            color: .green
        )
        let stripped = result.stripped
        // innerWidth + 2 = 7 characters of ▄
        #expect(stripped.count == 7)
        #expect(stripped.allSatisfy { $0 == "▄" })
    }

    @Test("blockBottomBorder uses upper half block character")
    func blockBottomBorderCharacter() {
        let result = BorderRenderer.blockBottomBorder(
            innerWidth: 5,
            color: .green
        )
        let stripped = result.stripped
        #expect(stripped.count == 7)
        #expect(stripped.allSatisfy { $0 == "▀" })
    }

    @Test("blockContentLine wraps with full block borders")
    func blockContentLine() {
        let result = BorderRenderer.blockContentLine(
            content: "Hello",
            innerWidth: 10,
            sectionColor: .blue
        )
        let stripped = result.stripped
        #expect(stripped.hasPrefix("█"))
        #expect(stripped.hasSuffix("█"))
    }

    @Test("blockContentLine pads content to innerWidth")
    func blockContentLinePadding() {
        let result = BorderRenderer.blockContentLine(
            content: "Hi",
            innerWidth: 8,
            sectionColor: .blue
        )
        let stripped = result.stripped
        // █ + padded content (8) + █ = 10
        #expect(stripped.count == 10)
    }

    @Test("blockSeparator produces correct width")
    func blockSeparatorWidth() {
        let result = BorderRenderer.blockSeparator(
            innerWidth: 5,
            foregroundColor: .red,
            backgroundColor: .blue
        )
        let stripped = result.stripped
        // innerWidth + 2 = 7
        #expect(stripped.count == 7)
    }

    @Test("blockSeparator uses default character")
    func blockSeparatorDefaultChar() {
        let result = BorderRenderer.blockSeparator(
            innerWidth: 3,
            foregroundColor: .red,
            backgroundColor: .blue
        )
        let stripped = result.stripped
        #expect(stripped.allSatisfy { $0 == "▀" })
    }

    @Test("blockSeparator with custom character")
    func blockSeparatorCustomChar() {
        let result = BorderRenderer.blockSeparator(
            innerWidth: 3,
            character: "▄",
            foregroundColor: .red,
            backgroundColor: .blue
        )
        let stripped = result.stripped
        #expect(stripped.allSatisfy { $0 == "▄" })
    }
}
