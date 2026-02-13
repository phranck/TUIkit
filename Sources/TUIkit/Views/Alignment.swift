//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Alignment.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Horizontal Alignment

/// Horizontal alignment for VStack and similar containers.
public enum HorizontalAlignment: Sendable {
    /// Align to the leading (left) edge.
    case leading

    /// Align to the center.
    case center

    /// Align to the trailing (right) edge.
    case trailing
}

// MARK: - Vertical Alignment

/// Vertical alignment for HStack and similar containers.
public enum VerticalAlignment: Sendable {
    /// Align to the top edge.
    case top

    /// Align to the vertical center.
    case center

    /// Align to the bottom edge.
    case bottom
}

// MARK: - Combined Alignment

/// Combined alignment for both axes.
public struct Alignment: Sendable, Equatable {
    /// The horizontal component.
    public let horizontal: HorizontalAlignment

    /// The vertical component.
    public let vertical: VerticalAlignment

    /// Creates a combined alignment.
    ///
    /// - Parameters:
    ///   - horizontal: The horizontal alignment.
    ///   - vertical: The vertical alignment.
    public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    // MARK: - Preset Alignments

    /// Top leading.
    public static let topLeading = Self(horizontal: .leading, vertical: .top)

    /// Top center.
    public static let top = Self(horizontal: .center, vertical: .top)

    /// Top trailing.
    public static let topTrailing = Self(horizontal: .trailing, vertical: .top)

    /// Center leading.
    public static let leading = Self(horizontal: .leading, vertical: .center)

    /// Center.
    public static let center = Self(horizontal: .center, vertical: .center)

    /// Center trailing.
    public static let trailing = Self(horizontal: .trailing, vertical: .center)

    /// Bottom leading.
    public static let bottomLeading = Self(horizontal: .leading, vertical: .bottom)

    /// Bottom center.
    public static let bottom = Self(horizontal: .center, vertical: .bottom)

    /// Bottom trailing.
    public static let bottomTrailing = Self(horizontal: .trailing, vertical: .bottom)
}
