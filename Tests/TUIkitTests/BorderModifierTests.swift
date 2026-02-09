//  TUIKit - Terminal UI Kit for Swift
//  BorderModifierTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Test Helpers

/// Creates a default render context for testing.
private func testContext(width: Int = 40, height: Int = 24) -> RenderContext {
    RenderContext(availableWidth: width, availableHeight: height)
}

// MARK: - BorderModifier Tests

@MainActor
@Suite("BorderModifier Tests")
struct BorderModifierTests {

    @Test(".border() renders with top and bottom borders")
    func borderModifierRenders() {
        let view = Text("Test").border(.line)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        // Top border + content + bottom border
        #expect(buffer.height == 3)
        #expect(buffer.lines[0].contains("┌"))
        #expect(buffer.lines[1].contains("Test"))
        #expect(buffer.lines[2].contains("└"))
    }

    @Test(".border() with empty content returns empty")
    func borderModifierEmptyContent() {
        let view = EmptyView().border(.line)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.isEmpty)
    }

    @Test(".border() with line style uses correct corner characters")
    func borderModifierLineStyle() {
        let view = Text("X").border(.line)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let topLine = buffer.lines[0].stripped
        let bottomLine = buffer.lines[buffer.height - 1].stripped

        #expect(topLine.hasPrefix("┌"))
        #expect(topLine.hasSuffix("┐"))
        #expect(bottomLine.hasPrefix("└"))
        #expect(bottomLine.hasSuffix("┘"))
    }

    @Test(".border() with doubleLine style uses correct characters")
    func borderModifierDoubleLineStyle() {
        let view = Text("X").border(.doubleLine)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let topLine = buffer.lines[0].stripped
        let bottomLine = buffer.lines[buffer.height - 1].stripped

        #expect(topLine.hasPrefix("╔"))
        #expect(topLine.hasSuffix("╗"))
        #expect(bottomLine.hasPrefix("╚"))
        #expect(bottomLine.hasSuffix("╝"))
    }

    @Test(".border() with rounded style uses correct characters")
    func borderModifierRoundedStyle() {
        let view = Text("X").border(.rounded)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let topLine = buffer.lines[0].stripped
        let bottomLine = buffer.lines[buffer.height - 1].stripped

        #expect(topLine.hasPrefix("╭"))
        #expect(topLine.hasSuffix("╮"))
        #expect(bottomLine.hasPrefix("╰"))
        #expect(bottomLine.hasSuffix("╯"))
    }

    @Test(".border() with heavy style uses correct characters")
    func borderModifierHeavyStyle() {
        let view = Text("X").border(.heavy)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let topLine = buffer.lines[0].stripped
        let bottomLine = buffer.lines[buffer.height - 1].stripped

        #expect(topLine.hasPrefix("┏"))
        #expect(topLine.hasSuffix("┓"))
        #expect(bottomLine.hasPrefix("┗"))
        #expect(bottomLine.hasSuffix("┛"))
    }

    @Test(".border() adds 4 to content width (2 border + 2 padding)")
    func borderModifierWidthOverhead() {
        let view = Text("ABCDE").border(.line)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        // Content "ABCDE" = 5, + 2 for padding + 2 for borders = 9
        let topLine = buffer.lines[0].stripped
        #expect(topLine.count == 9)
    }

    @Test(".border() content has 1 char padding on each side")
    func borderModifierContentPadding() {
        let view = Text("Hi").border(.line)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        // Content line should be: │ Hi │ (with spaces around "Hi")
        let contentLine = buffer.lines[1].stripped
        #expect(contentLine.hasPrefix("│ "))
        #expect(contentLine.hasSuffix(" │"))
        #expect(contentLine.contains(" Hi "))
    }
}

// MARK: - BorderStyle Tests

@MainActor
@Suite("BorderStyle Tests")
struct BorderStyleTests {

    @Test("Custom border style defaults T-junctions to vertical")
    func customBorderStyleDefaultTJunctions() {
        let custom = BorderStyle(
            topLeft: "A",
            topRight: "B",
            bottomLeft: "C",
            bottomRight: "D",
            horizontal: "E",
            vertical: "F"
        )
        #expect(custom.leftT == "F")
        #expect(custom.rightT == "F")
    }
}
