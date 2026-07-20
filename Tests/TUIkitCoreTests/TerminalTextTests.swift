//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TerminalTextTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkitCore

@Suite("Terminal Text Tests")
struct TerminalTextTests {
    @Test("Combining marks stay attached to their base cell")
    func combiningMarkWidth() {
        let grapheme: Character = "e\u{301}"

        #expect(grapheme.terminalWidth == 1)
        #expect(String(grapheme).strippedLength == 1)
    }

    @Test("Emoji sequences and East Asian characters use two cells")
    func wideGraphemeWidths() {
        #expect(Character("👩‍💻").terminalWidth == 2)
        #expect(Character("🇦🇹").terminalWidth == 2)
        #expect(Character("界").terminalWidth == 2)
    }

    @Test("Cell slicing never splits a wide grapheme")
    func wideGraphemeSlicing() {
        let text = "A界B"

        #expect(text.ansiAwarePrefix(visibleCount: 2) == "A")
        #expect(text.ansiAwareSuffix(droppingVisible: 1) == "界B")
        #expect(text.ansiAwareSuffix(droppingVisible: 2) == "B")
    }

    @Test("SGR and non-SGR CSI sequences have zero display width")
    func csiSequencesHaveZeroWidth() {
        let text = "\u{1B}[31mred\u{1B}[0m\u{1B}[2J!"

        #expect(text.stripped == "red!")
        #expect(text.strippedLength == 4)
    }

    @Test("OSC hyperlinks cannot survive terminal sanitization")
    func oscHyperlinksAreNeutralized() {
        let hyperlink = "\u{1B}]8;;https://example.com\u{07}click\u{1B}]8;;\u{07}"

        #expect(hyperlink.stripped == "click")
        #expect(hyperlink.sanitizedForTerminal == "click")
    }

    @Test("DCS payloads and control characters are neutralized")
    func deviceControlsAreNeutralized() {
        let input = "A\u{1B}Pmalicious\u{1B}\\B\u{07}C"

        #expect(input.stripped == "ABC")
        #expect(input.sanitizedForTerminal == "ABC")
    }
}
