//
//  ViewBuilder.swift
//  TUIkit
//
//  Result builder for declarative view composition.
//

/// A result builder for View hierarchies.
///
/// The `@ViewBuilder` enables a declarative syntax similar to SwiftUI:
///
/// ```swift
/// VStack {
///     Text("Line 1")
///     Text("Line 2")
///     if showMore {
///         Text("Line 3")
///     }
/// }
/// ```
///
/// The builder supports:
/// - Single views
/// - Multiple views (unlimited, via Parameter Packs)
/// - Conditionals (`if`, `if-else`)
/// - Optional views (`if let`)
/// - Arrays of views (`for-in`)
@resultBuilder
public struct ViewBuilder {

    // MARK: - Single View

    /// Builds a single view.
    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    // MARK: - Multiple Views (Parameter Pack)

    /// Builds multiple views into a TupleView using Swift Parameter Packs.
    ///
    /// This single overload replaces the previous 9 arity-specific `buildBlock`
    /// overloads (`TupleView2` through `TupleView10`), removing the 10-child limit.
    public static func buildBlock<each C: View>(
        _ content: repeat each C
    ) -> TupleView<repeat each C> {
        TupleView(repeat each content)
    }

    // MARK: - Conditionals

    /// Supports the true branch of an if-else.
    public static func buildEither<TrueContent: View, FalseContent: View>(
        first content: TrueContent
    ) -> ConditionalView<TrueContent, FalseContent> {
        .trueContent(content)
    }

    /// Supports the false branch of an if-else.
    public static func buildEither<TrueContent: View, FalseContent: View>(
        second content: FalseContent
    ) -> ConditionalView<TrueContent, FalseContent> {
        .falseContent(content)
    }

    /// Supports optional views (if let, if without else).
    public static func buildOptional<Content: View>(_ content: Content?) -> Content? {
        content
    }

    /// Supports availability limiting.
    public static func buildLimitedAvailability<Content: View>(_ content: Content) -> Content {
        content
    }

    // MARK: - Arrays

    /// Supports for-in loops.
    public static func buildArray<Content: View>(_ components: [Content]) -> ViewArray<Content> {
        ViewArray(components)
    }

    // MARK: - Expression

    /// Converts a single expression into a view.
    public static func buildExpression<Content: View>(_ expression: Content) -> Content {
        expression
    }

    /// Supports optional expressions.
    public static func buildExpression<Content: View>(_ expression: Content?) -> Content? {
        expression
    }
}
