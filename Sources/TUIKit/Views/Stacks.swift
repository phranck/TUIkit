//
//  Stacks.swift
//  TUIKit
//
//  Layout containers for vertical and horizontal arrangement.
//

// MARK: - VStack

/// A view that arranges its children vertically.
///
/// `VStack` stacks its child views on top of each other, from top to bottom.
/// This corresponds to the default behavior in a terminal.
///
/// # Example
///
/// ```swift
/// VStack {
///     Text("Line 1")
///     Text("Line 2")
///     Text("Line 3")
/// }
/// ```
///
/// # Alignment
///
/// ```swift
/// VStack(alignment: .center) {
///     Text("Short")
///     Text("Longer text")
/// }
/// ```
public struct VStack<Content: View>: View {
    /// The horizontal alignment of the children.
    public let alignment: HorizontalAlignment

    /// The vertical spacing between children.
    public let spacing: Int

    /// The content of the stack.
    public let content: Content

    /// Creates a vertical stack with the specified options.
    ///
    /// - Parameters:
    ///   - alignment: The horizontal alignment of children (default: .leading).
    ///   - spacing: The spacing between children in lines (default: 0).
    ///   - content: A ViewBuilder that defines the children.
    public init(
        alignment: HorizontalAlignment = .leading,
        spacing: Int = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never {
        fatalError("VStack is a primitive container and renders its children directly")
    }
}

// MARK: - HStack

/// A view that arranges its children horizontally.
///
/// `HStack` arranges its child views side by side, from left to right.
///
/// # Example
///
/// ```swift
/// HStack {
///     Text("[OK]")
///     Text("[Cancel]")
/// }
/// ```
///
/// # Alignment
///
/// ```swift
/// HStack(alignment: .top) {
///     Text("Left")
///     Text("Right")
/// }
/// ```
public struct HStack<Content: View>: View {
    /// The vertical alignment of the children.
    public let alignment: VerticalAlignment

    /// The horizontal spacing between children.
    public let spacing: Int

    /// The content of the stack.
    public let content: Content

    /// Creates a horizontal stack with the specified options.
    ///
    /// - Parameters:
    ///   - alignment: The vertical alignment of children (default: .center).
    ///   - spacing: The spacing between children in characters (default: 1).
    ///   - content: A ViewBuilder that defines the children.
    public init(
        alignment: VerticalAlignment = .center,
        spacing: Int = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never {
        fatalError("HStack is a primitive container and renders its children directly")
    }
}

// MARK: - ZStack

/// A view that stacks its children on top of each other (z-axis).
///
/// `ZStack` layers views on top of each other, with later views
/// appearing above earlier ones.
///
/// # Example
///
/// ```swift
/// ZStack {
///     Text("████████████████")
///     Text("    Overlay     ")
/// }
/// ```
public struct ZStack<Content: View>: View {
    /// The alignment of the children.
    public let alignment: Alignment

    /// The content of the stack.
    public let content: Content

    /// Creates a z-stack with the specified options.
    ///
    /// - Parameters:
    ///   - alignment: The alignment of children (default: .center).
    ///   - content: A ViewBuilder that defines the children.
    public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }

    public var body: Never {
        fatalError("ZStack is a primitive container and renders its children directly")
    }
}

// MARK: - Alignment Types

/// Horizontal alignment for VStack and similar containers.
public enum HorizontalAlignment: Sendable {
    /// Align to the leading (left) edge.
    case leading

    /// Align to the center.
    case center

    /// Align to the trailing (right) edge.
    case trailing
}

/// Vertical alignment for HStack and similar containers.
public enum VerticalAlignment: Sendable {
    /// Align to the top edge.
    case top

    /// Align to the vertical center.
    case center

    /// Align to the bottom edge.
    case bottom
}

/// Combined alignment for both axes.
public struct Alignment: Sendable {
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
    public static let topLeading = Alignment(horizontal: .leading, vertical: .top)

    /// Top center.
    public static let top = Alignment(horizontal: .center, vertical: .top)

    /// Top trailing.
    public static let topTrailing = Alignment(horizontal: .trailing, vertical: .top)

    /// Center leading.
    public static let leading = Alignment(horizontal: .leading, vertical: .center)

    /// Center.
    public static let center = Alignment(horizontal: .center, vertical: .center)

    /// Center trailing.
    public static let trailing = Alignment(horizontal: .trailing, vertical: .center)

    /// Bottom leading.
    public static let bottomLeading = Alignment(horizontal: .leading, vertical: .bottom)

    /// Bottom center.
    public static let bottom = Alignment(horizontal: .center, vertical: .bottom)

    /// Bottom trailing.
    public static let bottomTrailing = Alignment(horizontal: .trailing, vertical: .bottom)
}
