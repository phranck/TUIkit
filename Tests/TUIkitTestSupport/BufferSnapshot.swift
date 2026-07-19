//  🖥️ TUIKit — Terminal UI Kit for Swift
//  BufferSnapshot.swift
//
//  License: MIT

/// Dependency-free value representation of one rendered frame.
package struct BufferSnapshot: Sendable, Equatable {
    package let rawLines: [String]
    package let ansiStrippedLines: [String]
    package let width: Int
    package let height: Int

    package init(
        rawLines: [String],
        ansiStrippedLines: [String],
        width: Int,
        height: Int
    ) {
        self.rawLines = rawLines
        self.ansiStrippedLines = ansiStrippedLines
        self.width = width
        self.height = height
    }
}
