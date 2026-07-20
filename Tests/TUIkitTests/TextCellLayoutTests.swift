//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TextCellLayoutTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("Text Cell Layout Tests")
struct TextCellLayoutTests {
    @Test("Text wraps long words without splitting wide graphemes")
    func textWrapsByCells() {
        let context = RenderContext(
            availableWidth: 3,
            availableHeight: 4,
            tuiContext: TUIContext()
        )
        let text = Text("A界B")

        let size = text.sizeThatFits(proposal: ProposedSize(width: 3, height: nil), context: context)
        let buffer = renderToBuffer(text, context: context)

        #expect(size.width == 3)
        #expect(size.height == 2)
        #expect(buffer.lines.map(\.stripped) == ["A界", "B"])
    }

    @Test("Text measures sanitized content rather than embedded controls")
    func textNeutralizesControlsBeforeLayout() {
        let context = RenderContext(
            availableWidth: 2,
            availableHeight: 2,
            tuiContext: TUIContext()
        )
        let text = Text("A\u{1B}]0;owned\u{07}B")

        let size = text.sizeThatFits(proposal: ProposedSize(width: 2, height: nil), context: context)
        let buffer = renderToBuffer(text, context: context)

        #expect(size == ViewSize.fixed(2, 1))
        #expect(buffer.width == 2)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0].stripped == "AB")
    }

    @Test("Text consumes multiline terminal control payloads before wrapping")
    func textSanitizesBeforeSplittingLines() {
        let context = RenderContext(
            availableWidth: 20,
            availableHeight: 2,
            tuiContext: TUIContext()
        )
        let text = Text("A\u{1B}]0;hidden\npayload\u{07}B")

        let buffer = renderToBuffer(text, context: context)

        #expect(buffer.height == 1)
        #expect(buffer.lines[0].stripped == "AB")
    }

    @Test("Unfocused text fields clip and pad in terminal cells")
    func unfocusedFieldUsesCellWidth() {
        let context = RenderContext(availableWidth: 20, availableHeight: 1, tuiContext: TUIContext())
        let renderer = makeRenderer()

        let output = renderer.buildContent(
            text: "A界B",
            cursorPosition: 0,
            selectionRange: nil,
            isFocused: false,
            palette: context.environment.palette,
            cursorStyle: TextCursorStyle(animation: .none),
            cursorTimer: nil,
            contentWidth: 3
        )

        #expect(output.stripped == "A界")
        #expect(output.strippedLength == 3)
    }

    @Test("Focused text fields scroll on grapheme boundaries")
    func focusedFieldScrollsByCells() {
        let context = RenderContext(availableWidth: 20, availableHeight: 1, tuiContext: TUIContext())
        let renderer = makeRenderer()

        let output = renderer.buildContent(
            text: "AB界C",
            cursorPosition: 4,
            selectionRange: nil,
            isFocused: true,
            palette: context.environment.palette,
            cursorStyle: TextCursorStyle(animation: .none),
            cursorTimer: nil,
            contentWidth: 4
        )

        #expect(output.stripped == "界C█")
        #expect(output.strippedLength == 4)
    }

    private func makeRenderer() -> TextFieldContentRenderer {
        TextFieldContentRenderer(
            prompt: nil,
            isDisabled: false,
            displayCharacter: { $0 }
        )
    }
}
