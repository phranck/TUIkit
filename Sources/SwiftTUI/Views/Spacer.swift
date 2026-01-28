//
//  Spacer.swift
//  SwiftTUI
//
//  Flexible spacing elements for layout.
//

/// A flexible spacer that fills available space.
///
/// `Spacer` expands along the main axis of its container
/// and fills the available space between other views.
///
/// # Example in HStack
///
/// ```swift
/// HStack {
///     Text("Left")
///     Spacer()
///     Text("Right")
/// }
/// // Result: "Left                    Right"
/// ```
///
/// # Example in VStack
///
/// ```swift
/// VStack {
///     Text("Top")
///     Spacer()
///     Text("Bottom")
/// }
/// ```
public struct Spacer: TView {
    /// The minimum length of the spacer (in characters/lines).
    public let minLength: Int?

    /// Creates a spacer with optional minimum length.
    ///
    /// - Parameter minLength: The minimum length. If nil, the
    ///   spacer expands as much as possible.
    public init(minLength: Int? = nil) {
        self.minLength = minLength
    }

    public var body: Never {
        fatalError("Spacer is a primitive view")
    }
}

// MARK: - Divider

/// A visual separator between views.
///
/// `Divider` creates a horizontal or vertical line,
/// depending on the surrounding container.
///
/// # Example
///
/// ```swift
/// VStack {
///     Text("Section 1")
///     Divider()
///     Text("Section 2")
/// }
/// // Result:
/// // Section 1
/// // ─────────────
/// // Section 2
/// ```
public struct Divider: TView {
    /// The character used for the line.
    public var character: Character

    /// Creates a divider with the default character (─).
    public init() {
        self.character = "─"
    }

    /// Creates a divider with a custom character.
    ///
    /// - Parameter character: The character for the separator line.
    public init(character: Character) {
        self.character = character
    }

    public var body: Never {
        fatalError("Divider is a primitive view")
    }
}
