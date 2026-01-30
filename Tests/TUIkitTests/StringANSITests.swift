//
//  StringANSITests.swift
//  TUIkit
//
//  Tests for String+ANSI extensions: stripped, strippedLength, padToVisibleWidth.
//

import Testing

@testable import TUIkit

@Suite("String ANSI Extension Tests")
struct StringANSITests {

    // MARK: - stripped

    @Test("stripped removes ANSI codes from text")
    func strippedRemovesCodes() {
        let styled = "\u{1B}[31mHello\u{1B}[0m"
        #expect(styled.stripped == "Hello")
    }

    @Test("stripped on plain text returns unchanged")
    func strippedPlainText() {
        #expect("Hello World".stripped == "Hello World")
    }

    @Test("stripped on empty string returns empty")
    func strippedEmpty() {
        #expect("".stripped == "")
    }

    @Test("stripped removes nested ANSI codes")
    func strippedNested() {
        let text = "\u{1B}[1m\u{1B}[31mBold Red\u{1B}[0m"
        #expect(text.stripped == "Bold Red")
    }

    @Test("stripped removes multiple codes in one string")
    func strippedMultiple() {
        let text = "\u{1B}[32mGreen\u{1B}[0m and \u{1B}[34mBlue\u{1B}[0m"
        #expect(text.stripped == "Green and Blue")
    }

    @Test("stripped handles RGB color codes")
    func strippedRGB() {
        let text = "\u{1B}[38;2;255;0;0mRed\u{1B}[0m"
        #expect(text.stripped == "Red")
    }

    // MARK: - strippedLength

    @Test("strippedLength counts visible characters only")
    func strippedLengthVisible() {
        let styled = "\u{1B}[31mHello\u{1B}[0m"
        #expect(styled.strippedLength == 5)
    }

    @Test("strippedLength on plain text equals count")
    func strippedLengthPlain() {
        let text = "Hello"
        #expect(text.strippedLength == text.count)
    }

    @Test("strippedLength on empty string is zero")
    func strippedLengthEmpty() {
        #expect("".strippedLength == 0)
    }

    // MARK: - padToVisibleWidth

    @Test("padToVisibleWidth pads short string")
    func padShortString() {
        let result = "Hi".padToVisibleWidth(5)
        #expect(result == "Hi   ")
        #expect(result.count == 5)
    }

    @Test("padToVisibleWidth on exact width returns unchanged")
    func padExactWidth() {
        let result = "Hello".padToVisibleWidth(5)
        #expect(result == "Hello")
    }

    @Test("padToVisibleWidth on longer string returns unchanged")
    func padLongerString() {
        let result = "Hello World".padToVisibleWidth(5)
        #expect(result == "Hello World")
    }

    @Test("padToVisibleWidth with ANSI codes pads to visible width")
    func padWithANSI() {
        let styled = "\u{1B}[31mHi\u{1B}[0m" // "Hi" in red
        let result = styled.padToVisibleWidth(5)
        // Should pad based on visible width (2), not string length
        #expect(result.strippedLength == 5)
        #expect(result.stripped == "Hi   ")
    }

    @Test("padToVisibleWidth with zero target")
    func padZeroTarget() {
        let result = "Hi".padToVisibleWidth(0)
        #expect(result == "Hi") // unchanged, already wider
    }

    @Test("padToVisibleWidth on empty string")
    func padEmptyString() {
        let result = "".padToVisibleWidth(3)
        #expect(result == "   ")
    }
}
