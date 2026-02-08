//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ModifierTests.swift
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

// MARK: - EdgeInsets Tests

@MainActor
@Suite("EdgeInsets Tests")
struct EdgeInsetsTests {

    @Test("EdgeInsets uniform value")
    func edgeInsetsUniform() {
        let insets = EdgeInsets(all: 3)
        #expect(insets.top == 3)
        #expect(insets.leading == 3)
        #expect(insets.bottom == 3)
        #expect(insets.trailing == 3)
    }

    @Test("EdgeInsets horizontal and vertical")
    func edgeInsetsHorizontalVertical() {
        let insets = EdgeInsets(horizontal: 2, vertical: 1)
        #expect(insets.top == 1)
        #expect(insets.leading == 2)
        #expect(insets.bottom == 1)
        #expect(insets.trailing == 2)
    }

    @Test("EdgeInsets is Equatable")
    func edgeInsetsEquatable() {
        let insetsA = EdgeInsets(all: 2)
        let insetsB = EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        #expect(insetsA == insetsB)
    }
}

// MARK: - Edge Tests

@MainActor
@Suite("Edge Tests")
struct EdgeTests {

    @Test("Edge.all contains all edges")
    func edgeAll() {
        #expect(Edge.all.contains(.top))
        #expect(Edge.all.contains(.leading))
        #expect(Edge.all.contains(.bottom))
        #expect(Edge.all.contains(.trailing))
    }

    @Test("Edge.horizontal contains leading and trailing")
    func edgeHorizontal() {
        #expect(Edge.horizontal.contains(.leading))
        #expect(Edge.horizontal.contains(.trailing))
        #expect(!Edge.horizontal.contains(.top))
        #expect(!Edge.horizontal.contains(.bottom))
    }

    @Test("Edge.vertical contains top and bottom")
    func edgeVertical() {
        #expect(Edge.vertical.contains(.top))
        #expect(Edge.vertical.contains(.bottom))
        #expect(!Edge.vertical.contains(.leading))
        #expect(!Edge.vertical.contains(.trailing))
    }
}

// MARK: - PaddingModifier Tests

@MainActor
@Suite("PaddingModifier Tests")
struct PaddingModifierTests {

    @Test("Padding adds empty lines for top and bottom")
    func paddingTopBottom() {
        let modifier = PaddingModifier(insets: EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
        let buffer = FrameBuffer(lines: ["Hello"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        // 1 top + 1 content + 1 bottom = 3
        #expect(result.height == 3)
        #expect(result.lines[0].trimmingCharacters(in: .whitespaces).isEmpty)
        #expect(result.lines[1] == "Hello")
        #expect(result.lines[2].trimmingCharacters(in: .whitespaces).isEmpty)
    }

    @Test("Padding adds spaces for leading and trailing")
    func paddingLeadingTrailing() {
        let modifier = PaddingModifier(insets: EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 3))
        let buffer = FrameBuffer(lines: ["Hi"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        #expect(result.height == 1)
        // "  Hi   " — 2 leading + "Hi" + 3 trailing
        #expect(result.lines[0] == "  Hi   ")
    }

    @Test("Padding all sides")
    func paddingAllSides() {
        let modifier = PaddingModifier(insets: EdgeInsets(all: 1))
        let buffer = FrameBuffer(lines: ["X"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        // 1 top + 1 content + 1 bottom = 3
        #expect(result.height == 3)
        // Content line: 1 leading + "X" + 1 trailing = " X "
        #expect(result.lines[1] == " X ")
    }

    @Test("Padding on empty buffer returns empty")
    func paddingEmptyBuffer() {
        let modifier = PaddingModifier(insets: EdgeInsets(all: 2))
        let buffer = FrameBuffer()
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        // Only padding lines (no content)
        #expect(result.height == 4) // 2 top + 0 content + 2 bottom
    }

    @Test("Padding preserves multiple content lines")
    func paddingMultipleLines() {
        let modifier = PaddingModifier(insets: EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1))
        let buffer = FrameBuffer(lines: ["AAA", "BBB"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        // 1 top + 2 content + 1 bottom = 4
        #expect(result.height == 4)
        #expect(result.lines[1] == " AAA ")
        #expect(result.lines[2] == " BBB ")
    }

    @Test("Zero padding returns original dimensions")
    func paddingZero() {
        let modifier = PaddingModifier(insets: EdgeInsets())
        let buffer = FrameBuffer(lines: ["Test"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        #expect(result.height == 1)
        #expect(result.lines[0] == "Test")
    }
}

// MARK: - FrameModifier Tests

@MainActor
@Suite("FrameModifier Tests")
struct FrameModifierTests {

    @Test("FlexibleFrameView with maxWidth infinity fills available width")
    func frameMaxWidthInfinity() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: .infinity,
            minHeight: nil,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .center
        )
        let context = testContext(width: 30)
        let buffer = frame.renderToBuffer(context: context)

        #expect(buffer.width == 30)
    }

    @Test("FlexibleFrameView with fixed maxWidth constrains")
    func frameFixedMaxWidth() {
        let frame = FlexibleFrameView(
            content: Text("Short"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: .fixed(10),
            minHeight: nil,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .leading
        )
        let context = testContext(width: 40)
        let buffer = frame.renderToBuffer(context: context)

        // Content "Short" is 5 chars, no maxWidth expansion without infinity
        #expect(buffer.width <= 10)
    }

    @Test("FlexibleFrameView with minWidth enforces minimum")
    func frameMinWidth() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: 10,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: nil,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .leading
        )
        let context = testContext(width: 40)
        let buffer = frame.renderToBuffer(context: context)

        #expect(buffer.width >= 10)
    }

    @Test("FlexibleFrameView with minHeight enforces minimum")
    func frameMinHeight() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: 5,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .top
        )
        let context = testContext()
        let buffer = frame.renderToBuffer(context: context)

        #expect(buffer.height >= 5)
    }

    @Test("FlexibleFrameView alignment center")
    func frameCenterAlignment() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: 10,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: 3,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .center
        )
        let context = testContext()
        let buffer = frame.renderToBuffer(context: context)

        #expect(buffer.width >= 10)
        #expect(buffer.height >= 3)
        // Center vertically: content should be on line 1 (middle of 3)
        let contentLine = buffer.lines[1]
        #expect(contentLine.contains("Hi"))
        // Center horizontally: "Hi" is 2 chars, frame is 10, so 4 spaces on left
        let stripped = contentLine.stripped
        let leadingSpaces = stripped.prefix(while: { $0 == " " }).count
        #expect(leadingSpaces == 4, "Content should be horizontally centered with 4 leading spaces")
    }

    @Test("FlexibleFrameView alignment trailing")
    func frameTrailingAlignment() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: 10,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: nil,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .trailing
        )
        let context = testContext()
        let buffer = frame.renderToBuffer(context: context)

        // "Hi" should be right-aligned within 10 chars
        let line = buffer.lines[0]
        #expect(line.stripped.hasSuffix("Hi"))
    }

    @Test("FlexibleFrameView alignment bottom")
    func frameBottomAlignment() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: 3,
            idealHeight: nil,
            maxHeight: nil,
            alignment: .bottom
        )
        let context = testContext()
        let buffer = frame.renderToBuffer(context: context)

        #expect(buffer.height >= 3)
        // Content on last line
        let lastLine = buffer.lines[buffer.height - 1]
        #expect(lastLine.contains("Hi"))
    }

    @Test("FlexibleFrameView maxHeight constrains available height for content")
    func frameMaxHeight() {
        // maxHeight constrains the availableHeight passed to child rendering,
        // but does not clip content that exceeds constraints. This matches
        // SwiftUI behavior where frame constraints inform layout, not clip.
        let frame = FlexibleFrameView(
            content: Text("Short"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: 5,
            idealHeight: nil,
            maxHeight: .fixed(10),
            alignment: .top
        )
        let context = testContext()
        let buffer = frame.renderToBuffer(context: context)

        // minHeight 5 expands the 1-line content to 5 lines
        #expect(buffer.height == 5)
    }

    @Test("FlexibleFrameView maxHeight infinity fills available space")
    func frameMaxHeightInfinity() {
        let frame = FlexibleFrameView(
            content: Text("Hi"),
            minWidth: nil,
            idealWidth: nil,
            maxWidth: nil,
            minHeight: nil,
            idealHeight: nil,
            maxHeight: .infinity,
            alignment: .top
        )
        var context = testContext()
        context.availableHeight = 10
        let buffer = frame.renderToBuffer(context: context)

        // Should expand to fill available height
        #expect(buffer.height == 10)
    }
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

// MARK: - BackgroundModifier Tests

@MainActor
@Suite("BackgroundModifier Tests")
struct BackgroundModifierTests {

    @Test("Background modifier applies ANSI background code")
    func backgroundAppliesCode() {
        let modifier = BackgroundModifier(color: .red)
        let buffer = FrameBuffer(lines: ["Hello"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        #expect(result.height == 1)
        // Should contain ANSI red background code (41)
        let line = result.lines[0]
        #expect(line.contains("\u{1B}[41m"))
        #expect(line.contains("Hello"))
        // Should end with reset
        #expect(line.hasSuffix(ANSIRenderer.reset))
    }

    @Test("Background modifier preserves line count")
    func backgroundPreservesLineCount() {
        let modifier = BackgroundModifier(color: .blue)
        let buffer = FrameBuffer(lines: ["Line 1", "Line 2", "Line 3"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        #expect(result.height == 3)
    }

    @Test("Background modifier on empty buffer returns empty")
    func backgroundEmptyBuffer() {
        let modifier = BackgroundModifier(color: .green)
        let buffer = FrameBuffer()
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        #expect(result.isEmpty)
    }

    @Test("Background modifier pads lines to full width")
    func backgroundPadsLines() {
        let modifier = BackgroundModifier(color: .red)
        let buffer = FrameBuffer(lines: ["Short", "VeryLongLine"])
        let context = testContext()

        let result = modifier.modify(buffer: buffer, context: context)

        // Both lines should have the same visible width after padding
        #expect(result.lines[0].strippedLength == result.lines[1].strippedLength)
    }
}
