//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PerformanceOutputAssertions.swift
//
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

let performanceTestsEnabled = ProcessInfo.processInfo.environment["TUIKIT_RUN_PERFORMANCE_TESTS"] == "1"

struct PerformanceRenderOutput {
    let rawLines: [String]
    let strippedLines: [String]
}

/// Requires one untimed render to satisfy its semantic output contract before a benchmark starts.
@MainActor
func requireRenderedOutput<V: View>(
    _ view: V,
    context: RenderContext,
    matches predicate: (PerformanceRenderOutput) -> Bool
) throws {
    let rawLines = renderToBuffer(view, context: context).lines
    let output = PerformanceRenderOutput(
        rawLines: rawLines,
        strippedLines: rawLines.map(\.stripped)
    )
    try #require(predicate(output))
}

/// Produces the exact centered line layout used by vertical stacks.
func expectedCenteredLines(
    _ lines: [String],
    visibleCount: Int? = nil
) -> [String] {
    let width = lines.map(\.count).max() ?? 0
    let visibleLines = visibleCount.map { Array(lines.prefix($0)) } ?? lines

    return visibleLines.map { line in
        let padding = width - line.count
        let leftPadding = padding / 2
        let rightPadding = padding - leftPadding
        return String(repeating: " ", count: leftPadding)
            + line
            + String(repeating: " ", count: rightPadding)
    }
}
