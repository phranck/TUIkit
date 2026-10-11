//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TerminalGeometry.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Terminal Geometry

/// The single quantization policy from SwiftUI's continuous geometry to
/// whole terminal cells.
///
/// All public layout APIs accept `CGFloat` like SwiftUI; the renderer
/// operates on cells. Every conversion runs through this policy so macOS
/// and Linux produce identical layouts:
///
/// | Input                | Result                         |
/// |----------------------|--------------------------------|
/// | Fractional values    | Rounded half away from zero    |
/// | Negative values      | Clamped to 0 where sizes/spacing are consumed |
/// | `.infinity`          | `Int.max` (fills available space) |
/// | NaN                  | 0                              |
/// | Beyond `Int` range   | Clamped to `Int.min`/`Int.max` |
package enum TerminalGeometry {
    /// Converts a continuous value to whole cells.
    ///
    /// - Parameter value: The continuous value.
    /// - Returns: The deterministic cell count.
    package static func cells(_ value: CGFloat) -> Int {
        if value.isNaN { return 0 }
        if value == .infinity { return .max }
        if value == -.infinity { return .min }
        let rounded = value.rounded(.toNearestOrAwayFromZero)
        if rounded >= CGFloat(Int.max) { return .max }
        if rounded <= CGFloat(Int.min) { return .min }
        return Int(rounded)
    }

    /// Converts an alignment offset to whole cells.
    ///
    /// Alignment offsets round toward negative infinity (floor): centering
    /// a 1-cell child in a 4-cell container yields offset 1, matching the
    /// established terminal rendering. Sizes and spacing use ``cells(_:)``.
    ///
    /// - Parameter value: The continuous offset.
    /// - Returns: The deterministic cell offset.
    package static func alignmentOffset(_ value: CGFloat) -> Int {
        if value.isNaN { return 0 }
        if value == .infinity { return .max }
        if value == -.infinity { return .min }
        let rounded = value.rounded(.down)
        if rounded >= CGFloat(Int.max) { return .max }
        if rounded <= CGFloat(Int.min) { return .min }
        return Int(rounded)
    }

    /// Converts an optional spacing value to non-negative cells.
    ///
    /// - Parameters:
    ///   - value: The continuous spacing, or `nil` for the default.
    ///   - default: The default cell spacing when `value` is `nil`.
    /// - Returns: The deterministic, non-negative cell spacing.
    package static func spacing(_ value: CGFloat?, default defaultCells: Int) -> Int {
        guard let value else { return defaultCells }
        return max(0, cells(value))
    }
}
