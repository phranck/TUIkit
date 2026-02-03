//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Spacer.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

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
public struct Spacer: View, Equatable {
    /// The minimum length of the spacer (in characters/lines).
    let minLength: Int?

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
public struct Divider: View, Equatable {
    /// The character used for the line.
    var character: Character

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

// MARK: - Spacer Rendering

extension Spacer: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Standalone spacer (outside a stack): render as empty lines
        let count = minLength ?? 1
        return FrameBuffer(emptyWithHeight: count)
    }
}

// MARK: - Divider Rendering

extension Divider: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let line = String(repeating: character, count: context.availableWidth)
        return FrameBuffer(text: line)
    }
}
