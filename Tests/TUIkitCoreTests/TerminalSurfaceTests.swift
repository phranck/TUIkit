//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TerminalSurfaceTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkitCore

@Suite("Terminal Surface Tests")
struct TerminalSurfaceTests {
    @Test("Surface owns graphemes and wide-cell continuations")
    func graphemeOwnership() {
        let surface = TerminalSurface(lines: ["e\u{301}界"])

        #expect(surface.width == 3)
        #expect(surface.height == 1)
        #expect(surface.cell(atX: 0, y: 0)?.grapheme == "e\u{301}")
        #expect(surface.cell(atX: 1, y: 0)?.grapheme == "界")
        #expect(surface.cell(atX: 2, y: 0)?.isContinuation == true)
    }

    @Test("Surface models and encodes SGR state")
    func styleRoundTrip() {
        let input = "\u{1B}[1;31;44mStyled\u{1B}[0m plain"
        let surface = TerminalSurface(lines: [input])

        #expect(surface.plainLines == ["Styled plain"])
        #expect(surface.ansiEncodedLines == [input])
    }

    @Test("Surface parsing rejects terminal commands")
    func commandRejection() {
        let input = "A\u{1B}]0;owned\u{07}B\u{1B}[2JC"
        let surface = TerminalSurface(lines: [input])

        #expect(surface.plainLines == ["ABC"])
        #expect(surface.ansiEncodedLines == ["ABC"])
    }

    @Test("Clipping omits a grapheme that crosses the cell boundary")
    func wideCellClipping() {
        let surface = TerminalSurface(lines: ["A界B"])
        let clipped = surface.clipped(toWidth: 2, height: 1)

        #expect(clipped.width == 2)
        #expect(clipped.plainLines == ["A "])
    }

    @Test("Transparent overlay cells preserve the base")
    func transparentOverlay() {
        let base = TerminalSurface(lines: ["ABC"])
        let overlay = TerminalSurface(lines: [" X "])

        let result = base.composited(with: overlay, atX: 0, y: 0)

        #expect(result.plainLines == ["AXC"])
    }

    @Test("Styled spaces are opaque overlay cells")
    func styledSpaceOverlay() {
        let base = TerminalSurface(lines: ["ABC"])
        let overlay = TerminalSurface(lines: ["\u{1B}[41m \u{1B}[0m"])

        let result = base.composited(with: overlay, atX: 1, y: 0)

        #expect(result.plainLines == ["A C"])
        #expect(result.ansiEncodedLines[0].contains("\u{1B}[41m \u{1B}[0m"))
    }
}
