//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LayoutTypes.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Layout Types

/// How much space a parent proposes to a child view.
///
/// Similar to SwiftUI's `ProposedViewSize`. The parent suggests dimensions,
/// and the child can accept, ignore, or partially use them.
///
/// - `nil` means "use your ideal size" (no constraint)
/// - A specific value means "try to fit in this space"
public struct ProposedSize: Equatable, Sendable {
    /// The proposed width in characters, or nil for ideal width.
    public var width: Int?

    /// The proposed height in lines, or nil for ideal height.
    public var height: Int?

    /// No constraints - view should use its ideal size.
    public static let unspecified = ProposedSize(width: nil, height: nil)

    /// Creates a proposed size with specific dimensions.
    public init(width: Int?, height: Int?) {
        self.width = width
        self.height = height
    }

    /// Creates a proposed size with fixed dimensions.
    public static func fixed(_ width: Int, _ height: Int) -> ProposedSize {
        ProposedSize(width: width, height: height)
    }
}

/// The size a view needs and whether it can flex.
///
/// Views return this from `sizeThatFits` to communicate their space requirements.
/// Flexible views (like Spacer, TextField) can expand to fill available space.
/// Fixed views (like Text, Button) have a specific size they need.
public struct ViewSize: Equatable, Sendable {
    /// The width this view needs (minimum if flexible).
    public var width: Int

    /// The height this view needs (minimum if flexible).
    public var height: Int

    /// Whether this view can expand horizontally to fill available space.
    public var isWidthFlexible: Bool

    /// Whether this view can expand vertically to fill available space.
    public var isHeightFlexible: Bool

    /// Creates a view size with explicit flexibility flags.
    public init(width: Int, height: Int, isWidthFlexible: Bool = false, isHeightFlexible: Bool = false) {
        self.width = width
        self.height = height
        self.isWidthFlexible = isWidthFlexible
        self.isHeightFlexible = isHeightFlexible
    }

    /// Creates a fixed-size view that doesn't expand.
    public static func fixed(_ width: Int, _ height: Int) -> ViewSize {
        ViewSize(width: width, height: height, isWidthFlexible: false, isHeightFlexible: false)
    }

    /// Creates a flexible view that expands to fill available space.
    public static func flexible(minWidth: Int = 0, minHeight: Int = 0) -> ViewSize {
        ViewSize(width: minWidth, height: minHeight, isWidthFlexible: true, isHeightFlexible: true)
    }

    /// Creates a view that is flexible only horizontally.
    public static func flexibleWidth(minWidth: Int = 0, height: Int) -> ViewSize {
        ViewSize(width: minWidth, height: height, isWidthFlexible: true, isHeightFlexible: false)
    }

    /// Creates a view that is flexible only vertically.
    public static func flexibleHeight(width: Int, minHeight: Int = 0) -> ViewSize {
        ViewSize(width: width, height: minHeight, isWidthFlexible: false, isHeightFlexible: true)
    }
}
