//
//  Card.swift
//  SwiftTUI
//
//  A styled container view with border, background, and padding.
//

/// A container view that displays content in a card-like appearance.
///
/// `Card` combines border, background, and padding into a single
/// convenient container. It's useful for grouping related content.
///
/// # Example
///
/// ```swift
/// Card {
///     Text("Card Title")
///         .bold()
///     Text("Card content goes here")
/// }
///
/// Card(borderStyle: .rounded, borderColor: .cyan) {
///     Text("Styled Card")
/// }
/// ```
public struct Card<Content: View>: View {
    /// The content of the card.
    public let content: Content

    /// The border style.
    public let borderStyle: BorderStyle

    /// The border color.
    public let borderColor: Color?

    /// The background color (nil for transparent).
    public let backgroundColor: Color?

    /// The padding inside the card.
    public let padding: EdgeInsets

    /// Creates a card with the specified styling.
    ///
    /// - Parameters:
    ///   - borderStyle: The border style (default: .rounded).
    ///   - borderColor: The border color (default: nil).
    ///   - backgroundColor: The background color (default: nil).
    ///   - padding: The inner padding (default: 1 on all sides).
    ///   - content: The content of the card.
    public init(
        borderStyle: BorderStyle = .rounded,
        borderColor: Color? = nil,
        backgroundColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(all: 1),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.borderStyle = borderStyle
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.padding = padding
    }

    public var body: some View {
        // Build the card by composing modifiers
        if let bgColor = backgroundColor {
            content
                .padding(padding)
                .background(bgColor)
                .border(borderStyle, color: borderColor)
        } else {
            content
                .padding(padding)
                .border(borderStyle, color: borderColor)
        }
    }
}
