//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PerformanceOutputAssertions.swift
//
//  License: MIT

import Testing

@testable import TUIkit

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
