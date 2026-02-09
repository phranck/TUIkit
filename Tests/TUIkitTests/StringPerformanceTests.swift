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
    func analyzeStrippedLength() {
        print("\n=== strippedLength Performance ===")

        // Plain text (no ANSI)
        let plainShort = "Hello"
        _ = measure("Plain short (5 chars)", iterations: 10000) {
            _ = plainShort.strippedLength
        }

        let plainMedium = String(repeating: "A", count: 50)
        _ = measure("Plain medium (50 chars)", iterations: 10000) {
            _ = plainMedium.strippedLength
        }

        let plainLong = String(repeating: "B", count: 200)
        _ = measure("Plain long (200 chars)", iterations: 10000) {
            _ = plainLong.strippedLength
        }

        // With ANSI codes
        let ansiSimple = "\u{1B}[31mRed\u{1B}[0m"
        _ = measure("ANSI simple (1 color)", iterations: 10000) {
            _ = ansiSimple.strippedLength
        }

        let ansiComplex = "\u{1B}[1;31;48;2;255;128;0mStyled\u{1B}[0m Normal \u{1B}[34mBlue\u{1B}[0m"
        _ = measure("ANSI complex (multiple)", iterations: 10000) {
            _ = ansiComplex.strippedLength
        }

        // Long string with many ANSI codes
        var ansiMany = ""
        for i in 0..<20 {
            ansiMany += "\u{1B}[3\(i % 8)mWord\(i)\u{1B}[0m "
        }
        _ = measure("ANSI many (20 codes)", iterations: 5000) {
            _ = ansiMany.strippedLength
        }

        print("=====================================\n")
    }

    // MARK: - stripped Analysis

    @Test("Analyze stripped performance")
    func analyzeStripped() {
        print("\n=== stripped Performance ===")

        let plainShort = "Hello"
        _ = measure("Plain short (5 chars)", iterations: 10000) {
            _ = plainShort.stripped
        }

        let ansiSimple = "\u{1B}[31mRed\u{1B}[0m"
        _ = measure("ANSI simple (1 color)", iterations: 10000) {
            _ = ansiSimple.stripped
        }

        var ansiMany = ""
        for i in 0..<20 {
            ansiMany += "\u{1B}[3\(i % 8)mWord\(i)\u{1B}[0m "
        }
        _ = measure("ANSI many (20 codes)", iterations: 5000) {
            _ = ansiMany.stripped
        }

        print("=====================================\n")
    }

    // MARK: - padToVisibleWidth Analysis

    @Test("Analyze padToVisibleWidth performance")
    func analyzePadToVisibleWidth() {
        print("\n=== padToVisibleWidth Performance ===")

        let plain = "Hello"
        _ = measure("Plain padding", iterations: 10000) {
            _ = plain.padToVisibleWidth(80)
        }

        let ansi = "\u{1B}[31mRed\u{1B}[0m"
        _ = measure("ANSI padding", iterations: 10000) {
            _ = ansi.padToVisibleWidth(80)
        }

        // Already at target width
        let exact = String(repeating: "X", count: 80)
        _ = measure("No padding needed", iterations: 10000) {
            _ = exact.padToVisibleWidth(80)
        }

        print("=====================================\n")
    }

    // MARK: - ANSIRenderer Analysis

    @Test("Analyze ANSIRenderer.render performance")
    func analyzeANSIRenderer() {
        print("\n=== ANSIRenderer.render Performance ===")

        let text = "Hello World"

        // No style
        let noStyle = TextStyle()
        _ = measure("No style", iterations: 10000) {
            _ = ANSIRenderer.render(text, with: noStyle)
        }

        // Bold only
        var boldStyle = TextStyle()
        boldStyle.isBold = true
        _ = measure("Bold only", iterations: 10000) {
            _ = ANSIRenderer.render(text, with: boldStyle)
        }

        // Foreground color
        var colorStyle = TextStyle()
        colorStyle.foregroundColor = .red
        _ = measure("Foreground color", iterations: 10000) {
            _ = ANSIRenderer.render(text, with: colorStyle)
        }

        // Full style
        var fullStyle = TextStyle()
        fullStyle.isBold = true
        fullStyle.foregroundColor = .red
        fullStyle.backgroundColor = .blue
        _ = measure("Full style (bold+fg+bg)", iterations: 10000) {
            _ = ANSIRenderer.render(text, with: fullStyle)
        }

        // RGB color
        var rgbStyle = TextStyle()
        rgbStyle.foregroundColor = .rgb(255, 128, 0)
        _ = measure("RGB color", iterations: 10000) {
            _ = ANSIRenderer.render(text, with: rgbStyle)
        }

        print("=====================================\n")
    }

    // MARK: - ANSIRenderer.colorize Analysis

    @Test("Analyze ANSIRenderer.colorize performance")
    func analyzeColorize() {
        print("\n=== ANSIRenderer.colorize Performance ===")

        let text = "Hello"

        _ = measure("No color", iterations: 10000) {
            _ = ANSIRenderer.colorize(text)
        }

        _ = measure("Foreground only", iterations: 10000) {
            _ = ANSIRenderer.colorize(text, foreground: .red)
        }

        _ = measure("Foreground + bold", iterations: 10000) {
            _ = ANSIRenderer.colorize(text, foreground: .red, bold: true)
        }

        _ = measure("Foreground + background", iterations: 10000) {
            _ = ANSIRenderer.colorize(text, foreground: .red, background: .blue)
        }

        print("=====================================\n")
    }

    // MARK: - ansiAwarePrefix/Suffix Analysis

    @Test("Analyze ANSI-aware string splitting performance")
    func analyzeANSIAwareSplitting() {
        print("\n=== ANSI-Aware Splitting Performance ===")

        let plain = "Hello World Test String"
        _ = measure("Plain prefix", iterations: 10000) {
            _ = plain.ansiAwarePrefix(visibleCount: 10)
        }

        _ = measure("Plain suffix", iterations: 10000) {
            _ = plain.ansiAwareSuffix(droppingVisible: 10)
        }

        let ansi = "\u{1B}[31mHello \u{1B}[32mWorld \u{1B}[34mTest\u{1B}[0m String"
        _ = measure("ANSI prefix", iterations: 10000) {
            _ = ansi.ansiAwarePrefix(visibleCount: 10)
        }

        _ = measure("ANSI suffix", iterations: 10000) {
            _ = ansi.ansiAwareSuffix(droppingVisible: 10)
        }

        print("=====================================\n")
    }

    // MARK: - Regex vs Manual Comparison

    @Test("Compare regex vs manual ANSI detection")
    func compareRegexVsManual() {
        print("\n=== Regex vs Manual Comparison ===")

        let testStrings = [
            "Plain text no ANSI",
            "\u{1B}[31mRed\u{1B}[0m",
            "\u{1B}[1;31;48;2;255;128;0mComplex\u{1B}[0m",
        ]

        for (i, str) in testStrings.enumerated() {
            print("  String \(i + 1):")

            // Current regex-based approach
            _ = measure("    Regex strippedLength", iterations: 10000) {
                _ = str.strippedLength
            }

            // Manual counting (similar to ansiAwarePrefix logic)
            _ = measure("    Manual count", iterations: 10000) {
                _ = manualVisibleLength(str)
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
