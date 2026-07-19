//  TUIKit - Terminal UI Kit for Swift
//  StringPerformanceTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

// MARK: - String Performance Tests

/// Performance tests for string operations, especially ANSI handling.
@MainActor
@Suite("String Performance Tests")
struct StringPerformanceTests {

    /// Measures execution time of a block over multiple iterations.
    ///
    /// Uses `Date` instead of `CFAbsoluteTimeGetCurrent` because CoreFoundation
    /// timing functions are not available on Linux. The precision difference
    /// is negligible for performance benchmarks at millisecond granularity.
    private func measure(_ name: String, iterations: Int = 1000, block: () -> Void) -> TimeInterval {
        let start = Date()
        for _ in 0..<iterations {
            block()
        }
        let time = Date().timeIntervalSince(start)
        let perIteration = (time / Double(iterations)) * 1000
        print("  \(name): \(String(format: "%.4f", perIteration))ms per iteration")
        return time
    }

    // MARK: - strippedLength Analysis

    @Test("Analyze strippedLength performance")
    func analyzeStrippedLength() throws {
        print("\n=== strippedLength Performance ===")

        // Plain text (no ANSI)
        let plainShort = "Hello"
        try #require(plainShort.strippedLength == 5)
        _ = measure("Plain short (5 chars)", iterations: 10000) {
            _ = plainShort.strippedLength
        }

        let plainMedium = String(repeating: "A", count: 50)
        try #require(plainMedium.strippedLength == 50)
        _ = measure("Plain medium (50 chars)", iterations: 10000) {
            _ = plainMedium.strippedLength
        }

        let plainLong = String(repeating: "B", count: 200)
        try #require(plainLong.strippedLength == 200)
        _ = measure("Plain long (200 chars)", iterations: 10000) {
            _ = plainLong.strippedLength
        }

        // With ANSI codes
        let ansiSimple = "\u{1B}[31mRed\u{1B}[0m"
        try #require(ansiSimple.strippedLength == 3)
        _ = measure("ANSI simple (1 color)", iterations: 10000) {
            _ = ansiSimple.strippedLength
        }

        let ansiComplex = "\u{1B}[1;31;48;2;255;128;0mStyled\u{1B}[0m Normal \u{1B}[34mBlue\u{1B}[0m"
        try #require(ansiComplex.strippedLength == "Styled Normal Blue".count)
        _ = measure("ANSI complex (multiple)", iterations: 10000) {
            _ = ansiComplex.strippedLength
        }

        // Long string with many ANSI codes
        var ansiMany = ""
        for codeIndex in 0..<20 {
            ansiMany += "\u{1B}[3\(codeIndex % 8)mWord\(codeIndex)\u{1B}[0m "
        }
        let ansiManyPlainText = (0..<20).map { "Word\($0) " }.joined()
        try #require(ansiMany.strippedLength == ansiManyPlainText.count)
        _ = measure("ANSI many (20 codes)", iterations: 5000) {
            _ = ansiMany.strippedLength
        }

        print("=====================================\n")
    }

    // MARK: - stripped Analysis

    @Test("Analyze stripped performance")
    func analyzeStripped() throws {
        print("\n=== stripped Performance ===")

        let plainShort = "Hello"
        try #require(plainShort.stripped == plainShort)
        _ = measure("Plain short (5 chars)", iterations: 10000) {
            _ = plainShort.stripped
        }

        let ansiSimple = "\u{1B}[31mRed\u{1B}[0m"
        try #require(ansiSimple.stripped == "Red")
        _ = measure("ANSI simple (1 color)", iterations: 10000) {
            _ = ansiSimple.stripped
        }

        var ansiMany = ""
        for codeIndex in 0..<20 {
            ansiMany += "\u{1B}[3\(codeIndex % 8)mWord\(codeIndex)\u{1B}[0m "
        }
        let ansiManyPlainText = (0..<20).map { "Word\($0) " }.joined()
        try #require(ansiMany.stripped == ansiManyPlainText)
        _ = measure("ANSI many (20 codes)", iterations: 5000) {
            _ = ansiMany.stripped
        }

        print("=====================================\n")
    }

    // MARK: - padToVisibleWidth Analysis

    @Test("Analyze padToVisibleWidth performance")
    func analyzePadToVisibleWidth() throws {
        print("\n=== padToVisibleWidth Performance ===")

        let plain = "Hello"
        try #require(plain.padToVisibleWidth(80) == plain + String(repeating: " ", count: 75))
        _ = measure("Plain padding", iterations: 10000) {
            _ = plain.padToVisibleWidth(80)
        }

        let ansi = "\u{1B}[31mRed\u{1B}[0m"
        let paddedANSI = ansi.padToVisibleWidth(80)
        try #require(paddedANSI == ansi + String(repeating: " ", count: 77))
        _ = measure("ANSI padding", iterations: 10000) {
            _ = ansi.padToVisibleWidth(80)
        }

        // Already at target width
        let exact = String(repeating: "X", count: 80)
        try #require(exact.padToVisibleWidth(80) == exact)
        _ = measure("No padding needed", iterations: 10000) {
            _ = exact.padToVisibleWidth(80)
        }

        print("=====================================\n")
    }

    // MARK: - ANSIRenderer Analysis

    @Test("Analyze ANSIRenderer.render performance")
    func analyzeANSIRenderer() throws {
        print("\n=== ANSIRenderer.render Performance ===")

        let text = "Hello World"

        // No style
        let noStyle = TextStyle()
        try #require(ANSIRenderer.render(text, with: noStyle) == text)
        _ = measure("No style", iterations: 10000) {
            _ = ANSIRenderer.render(text, with: noStyle)
        }

        // Bold only
        var boldStyle = TextStyle()
        boldStyle.isBold = true
        let boldOutput = ANSIRenderer.render(text, with: boldStyle)
        try #require(boldOutput.stripped == text && boldOutput.contains("\u{1B}[1m"))
        _ = measure("Bold only", iterations: 10000) {
            _ = ANSIRenderer.render(text, with: boldStyle)
        }

        // Foreground color
        var colorStyle = TextStyle()
        colorStyle.foregroundColor = .red
        let colorOutput = ANSIRenderer.render(text, with: colorStyle)
        try #require(colorOutput.stripped == text && colorOutput.contains("\u{1B}[31m"))
        _ = measure("Foreground color", iterations: 10000) {
            _ = ANSIRenderer.render(text, with: colorStyle)
        }

        // Full style
        var fullStyle = TextStyle()
        fullStyle.isBold = true
        fullStyle.foregroundColor = .red
        fullStyle.backgroundColor = .blue
        let fullStyleOutput = ANSIRenderer.render(text, with: fullStyle)
        try #require(fullStyleOutput == "\u{1B}[1;31;44m\(text)\u{1B}[0m")
        _ = measure("Full style (bold+fg+bg)", iterations: 10000) {
            _ = ANSIRenderer.render(text, with: fullStyle)
        }

        // RGB color
        var rgbStyle = TextStyle()
        rgbStyle.foregroundColor = .rgb(255, 128, 0)
        let rgbOutput = ANSIRenderer.render(text, with: rgbStyle)
        try #require(rgbOutput.stripped == text && rgbOutput.contains("38;2;255;128;0"))
        _ = measure("RGB color", iterations: 10000) {
            _ = ANSIRenderer.render(text, with: rgbStyle)
        }

        print("=====================================\n")
    }

    // MARK: - ANSIRenderer.colorize Analysis

    @Test("Analyze ANSIRenderer.colorize performance")
    func analyzeColorize() throws {
        print("\n=== ANSIRenderer.colorize Performance ===")

        let text = "Hello"

        try #require(ANSIRenderer.colorize(text) == text)
        _ = measure("No color", iterations: 10000) {
            _ = ANSIRenderer.colorize(text)
        }

        let foregroundOutput = ANSIRenderer.colorize(text, foreground: .red)
        try #require(foregroundOutput.stripped == text && foregroundOutput.contains("\u{1B}[31m"))
        _ = measure("Foreground only", iterations: 10000) {
            _ = ANSIRenderer.colorize(text, foreground: .red)
        }

        let boldOutput = ANSIRenderer.colorize(text, foreground: .red, bold: true)
        try #require(boldOutput.stripped == text && boldOutput.contains("\u{1B}[1;31m"))
        _ = measure("Foreground + bold", iterations: 10000) {
            _ = ANSIRenderer.colorize(text, foreground: .red, bold: true)
        }

        let backgroundOutput = ANSIRenderer.colorize(text, foreground: .red, background: .blue)
        try #require(backgroundOutput.stripped == text && backgroundOutput.contains("\u{1B}[31;44m"))
        _ = measure("Foreground + background", iterations: 10000) {
            _ = ANSIRenderer.colorize(text, foreground: .red, background: .blue)
        }

        print("=====================================\n")
    }

    // MARK: - ansiAwarePrefix/Suffix Analysis

    @Test("Analyze ANSI-aware string splitting performance")
    func analyzeANSIAwareSplitting() throws {
        print("\n=== ANSI-Aware Splitting Performance ===")

        let plain = "Hello World Test String"
        try #require(plain.ansiAwarePrefix(visibleCount: 10) == String(plain.prefix(10)))
        _ = measure("Plain prefix", iterations: 10000) {
            _ = plain.ansiAwarePrefix(visibleCount: 10)
        }

        try #require(plain.ansiAwareSuffix(droppingVisible: 10) == String(plain.dropFirst(10)))
        _ = measure("Plain suffix", iterations: 10000) {
            _ = plain.ansiAwareSuffix(droppingVisible: 10)
        }

        let ansi = "\u{1B}[31mHello \u{1B}[32mWorld \u{1B}[34mTest\u{1B}[0m String"
        let expectedANSIPrefix = "\u{1B}[31mHello \u{1B}[32mWorl"
        try #require(ansi.ansiAwarePrefix(visibleCount: 10) == expectedANSIPrefix)
        _ = measure("ANSI prefix", iterations: 10000) {
            _ = ansi.ansiAwarePrefix(visibleCount: 10)
        }

        let expectedANSISuffix = "d \u{1B}[34mTest\u{1B}[0m String"
        try #require(ansi.ansiAwareSuffix(droppingVisible: 10) == expectedANSISuffix)
        _ = measure("ANSI suffix", iterations: 10000) {
            _ = ansi.ansiAwareSuffix(droppingVisible: 10)
        }

        print("=====================================\n")
    }

    // MARK: - Regex vs Manual Comparison

    @Test("Compare regex vs manual ANSI detection")
    func compareRegexVsManual() throws {
        print("\n=== Regex vs Manual Comparison ===")

        let testStrings = [
            "Plain text no ANSI",
            "\u{1B}[31mRed\u{1B}[0m",
            "\u{1B}[1;31;48;2;255;128;0mComplex\u{1B}[0m",
        ]

        for (stringIndex, string) in testStrings.enumerated() {
            print("  String \(stringIndex + 1):")
            try #require(string.strippedLength == manualVisibleLength(string))

            // Current regex-based approach
            _ = measure("    Regex strippedLength", iterations: 10000) {
                _ = string.strippedLength
            }

            // Manual counting (similar to ansiAwarePrefix logic)
            _ = measure("    Manual count", iterations: 10000) {
                _ = manualVisibleLength(string)
            }
        }

        print("=====================================\n")
    }

    // Manual visible length calculation for comparison
    private func manualVisibleLength(_ string: String) -> Int {
        var count = 0
        var index = string.startIndex

        while index < string.endIndex {
            if string[index] == "\u{1B}" {
                // Skip ANSI sequence
                index = string.index(after: index)
                if index < string.endIndex && string[index] == "[" {
                    index = string.index(after: index)
                    while index < string.endIndex && (string[index].isNumber || string[index] == ";") {
                        index = string.index(after: index)
                    }
                    if index < string.endIndex && string[index].isLetter {
                        index = string.index(after: index)
                    }
                }
            } else {
                count += 1
                index = string.index(after: index)
            }
        }

        return count
    }
}
