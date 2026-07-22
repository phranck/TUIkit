//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PinnedScrollableViews.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Pinned Scrollable Views

/// The kinds of scrollable-view child content that pin to the visible
/// bounds of a lazy stack.
///
/// Matches SwiftUI's option set. Lazy stacks accept the option for API
/// parity today; pinning takes visual effect once true viewport-driven
/// laziness lands (issue #25).
public struct PinnedScrollableViews: OptionSet, Sendable {
    /// The raw bitmask value for this option set.
    public let rawValue: UInt32

    /// Creates an option set from a raw bitmask value.
    ///
    /// - Parameter rawValue: The bitmask value.
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// The header views of each section stay pinned.
    public static let sectionHeaders = Self(rawValue: 1 << 0)

    /// The footer views of each section stay pinned.
    public static let sectionFooters = Self(rawValue: 1 << 1)
}
