//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ProgressViewTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Test Helpers

/// Creates a default render context for testing.
private func testContext(width: Int = 30, height: Int = 24) -> RenderContext {
    RenderContext(availableWidth: width, availableHeight: height)
}

// MARK: - ProgressView Rendering Tests

@MainActor
@Suite("ProgressView Tests")
struct ProgressViewTests {

    @Test("Progress bar renders single line without label")
    func barOnlyIsSingleLine() {
        let view = ProgressView(value: 0.5)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 1)
        #expect(buffer.width == 30)
    }

    @Test("Progress bar with label renders two lines")
    func barWithLabelIsTwoLines() {
        let view = ProgressView("Loading", value: 0.5)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 2)
        #expect(buffer.lines[0].contains("Loading"))
    }

    @Test("Progress bar with ViewBuilder label renders two lines")
    func barWithViewBuilderLabel() {
        let view = ProgressView(value: 0.7) {
            Text("Downloading")
        }
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 2)
        #expect(buffer.lines[0].contains("Downloading"))
    }

    @Test("Progress bar with label and currentValueLabel shows both")
    func barWithLabelAndValueLabel() {
        let view = ProgressView(value: 0.5) {
            Text("Task")
        } currentValueLabel: {
            Text("50%")
        }
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 2)
        #expect(buffer.lines[0].contains("Task"))
        #expect(buffer.lines[0].contains("50%"))
    }

    @Test("Default line style contains filled and empty block characters")
    func lineStyleContainsBlockCharacters() {
        let view = ProgressView(value: 0.5)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        #expect(barLine.contains("█"))
        #expect(barLine.contains("░"))
    }

    @Test("0% progress shows all empty blocks")
    func zeroProgressAllEmpty() {
        let view = ProgressView(value: 0.0)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        #expect(!barLine.contains("█"))
        #expect(barLine.contains("░"))
    }

    @Test("100% progress shows all filled blocks")
    func fullProgressAllFilled() {
        let view = ProgressView(value: 1.0)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        #expect(barLine.contains("█"))
        #expect(!barLine.contains("░"))
    }

    @Test("Bar width equals available width")
    func barFillsAvailableWidth() {
        let view = ProgressView(value: 0.5)
        let context = testContext(width: 20)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        #expect(barLine.count == 20)
    }

    @Test("Filled count scales with fraction at 50%")
    func filledCountScalesWithFraction() {
        let view = ProgressView(value: 0.5)
        let context = testContext(width: 20)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        let filledCount = barLine.filter { $0 == "█" }.count
        let emptyCount = barLine.filter { $0 == "░" }.count

        #expect(filledCount == 10)
        #expect(emptyCount == 10)
    }
}

// MARK: - Style Tests

@MainActor
@Suite("ProgressView Style Tests")
struct ProgressViewStyleTests {

    @Test("Block style uses only █ and ░ characters")
    func blockStyleWholeBlocks() {
        let view = ProgressView(value: 0.33).progressBarStyle(.block)
        let context = testContext(width: 10)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        let allExpected = barLine.allSatisfy { $0 == "█" || $0 == "░" }
        #expect(allExpected)
    }

    @Test("BlockFine style uses fractional blocks for sub-character precision")
    func blockFineStyleFractionalBlocks() {
        // 33% of 10 = 3.3 cells → 3 full + fractional
        let view = ProgressView(value: 0.33).progressBarStyle(.blockFine)
        let context = testContext(width: 10)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        let fractionalChars: Set<Character> = ["▏", "▎", "▍", "▌", "▋", "▊", "▉"]
        let hasFractional = barLine.contains { fractionalChars.contains($0) }
        #expect(hasFractional)
    }

    @Test("Shade style uses ▓ and ░ characters")
    func shadeStyleCharacters() {
        let view = ProgressView(value: 0.5).progressBarStyle(.shade)
        let context = testContext(width: 20)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        #expect(barLine.contains("▓"))
        #expect(barLine.contains("░"))
    }

    @Test("Bar style uses ▌ and ─ characters")
    func barStyleCharacters() {
        let view = ProgressView(value: 0.5).progressBarStyle(.bar)
        let context = testContext(width: 20)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        #expect(barLine.contains("▌"))
        #expect(barLine.contains("─"))
    }

    @Test("Dot style uses ▬, ● head, and ─ characters")
    func dotStyleCharacters() {
        let view = ProgressView(value: 0.5).progressBarStyle(.dot)
        let context = testContext(width: 20)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        #expect(barLine.contains("▬"))
        #expect(barLine.contains("●"))
        #expect(barLine.contains("─"))
    }

    @Test("Style modifier returns correct style")
    func styleModifierWorks() {
        let view = ProgressView(value: 0.5).progressBarStyle(.shade)
        #expect(view.style == .shade)
    }

    @Test("All styles render correct width")
    func allStylesCorrectWidth() {
        let styles: [ProgressBarStyle] = [.block, .blockFine, .shade, .bar, .dot]
        let context = testContext(width: 20)

        for style in styles {
            let view = ProgressView(value: 0.5).progressBarStyle(style)
            let buffer = renderToBuffer(view, context: context)
            let barLine = buffer.lines[0].stripped
            #expect(barLine.count == 20, "Style \(style) should render width 20, got \(barLine.count)")
        }
    }

    @Test("Dot style at 0% shows no head and all empty")
    func dotStyleZeroPercent() {
        let view = ProgressView(value: 0.0).progressBarStyle(.dot)
        let context = testContext(width: 10)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        #expect(!barLine.contains("●"))
        #expect(!barLine.contains("▬"))
        #expect(barLine.contains("─"))
    }

    @Test("Dot style at 100% shows head at end")
    func dotStyleFullPercent() {
        let view = ProgressView(value: 1.0).progressBarStyle(.dot)
        let context = testContext(width: 10)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        #expect(barLine.contains("●"))
        #expect(barLine.contains("▬"))
        #expect(!barLine.contains("─"))
    }
}

// MARK: - Edge Case Tests

@MainActor
@Suite("ProgressView Edge Cases")
struct ProgressViewEdgeCaseTests {

    @Test("Value greater than total clamps to 100%")
    func valueExceedsTotalClamped() {
        let view = ProgressView(value: 2.0, total: 1.0)
        let context = testContext(width: 10)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        let filledCount = barLine.filter { $0 == "█" }.count
        #expect(filledCount == 10)
    }

    @Test("Negative value clamps to 0%")
    func negativeValueClamped() {
        let view = ProgressView(value: -0.5)
        let context = testContext(width: 10)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        let filledCount = barLine.filter { $0 == "█" }.count
        #expect(filledCount == 0)
    }

    @Test("Zero total produces 0% bar")
    func zeroTotalShowsEmpty() {
        let view = ProgressView(value: 5.0, total: 0.0)
        let context = testContext(width: 10)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        let filledCount = barLine.filter { $0 == "█" }.count
        #expect(filledCount == 0)
    }

    @Test("nil value renders empty bar (indeterminate fallback)")
    func nilValueRendersEmptyBar() {
        let view = ProgressView<EmptyView, EmptyView>(value: Optional<Double>.none)
        let context = testContext(width: 10)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        let filledCount = barLine.filter { $0 == "█" }.count
        #expect(filledCount == 0)
    }

    @Test("Custom total works correctly")
    func customTotal() {
        let view = ProgressView(value: 3.0, total: 10.0)
        let context = testContext(width: 10)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        let filledCount = barLine.filter { $0 == "█" }.count
        #expect(filledCount == 3)  // 30% of 10
    }

    @Test("Float value works via BinaryFloatingPoint generic")
    func floatValueWorks() {
        let view = ProgressView(value: Float(0.5))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 1)
        #expect(buffer.lines[0].contains("█"))
    }

    @Test("Width of 1 renders single character")
    func singleCharWidth() {
        let view = ProgressView(value: 1.0)
        let context = testContext(width: 1)
        let buffer = renderToBuffer(view, context: context)

        let barLine = buffer.lines[0].stripped
        #expect(barLine == "█")
    }
}
