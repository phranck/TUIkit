//
//  ViewBuilder.swift
//  SwiftTUI
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
/// - Multiple views (up to 10)
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

    // MARK: - Multiple Views (Tuple Views)

    /// Builds two views into a TupleView.
    public static func buildBlock<C0: View, C1: View>(
        _ c0: C0,
        _ c1: C1
    ) -> TupleView2<C0, C1> {
        TupleView2(c0, c1)
    }

    /// Builds three views into a TupleView.
    public static func buildBlock<C0: View, C1: View, C2: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2
    ) -> TupleView3<C0, C1, C2> {
        TupleView3(c0, c1, c2)
    }

    /// Builds four views into a TupleView.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3
    ) -> TupleView4<C0, C1, C2, C3> {
        TupleView4(c0, c1, c2, c3)
    }

    /// Builds five views into a TupleView.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4
    ) -> TupleView5<C0, C1, C2, C3, C4> {
        TupleView5(c0, c1, c2, c3, c4)
    }

    /// Builds six views into a TupleView.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5
    ) -> TupleView6<C0, C1, C2, C3, C4, C5> {
        TupleView6(c0, c1, c2, c3, c4, c5)
    }

    /// Builds seven views into a TupleView.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6
    ) -> TupleView7<C0, C1, C2, C3, C4, C5, C6> {
        TupleView7(c0, c1, c2, c3, c4, c5, c6)
    }

    /// Builds eight views into a TupleView.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7
    ) -> TupleView8<C0, C1, C2, C3, C4, C5, C6, C7> {
        TupleView8(c0, c1, c2, c3, c4, c5, c6, c7)
    }

    /// Builds nine views into a TupleView.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7,
        _ c8: C8
    ) -> TupleView9<C0, C1, C2, C3, C4, C5, C6, C7, C8> {
        TupleView9(c0, c1, c2, c3, c4, c5, c6, c7, c8)
    }

    /// Builds ten views into a TupleView.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View, C9: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7,
        _ c8: C8,
        _ c9: C9
    ) -> TupleView10<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9> {
        TupleView10(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9)
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
