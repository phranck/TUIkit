//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewBuilder.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore
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
@MainActor
@resultBuilder
public struct ViewBuilder {

    // MARK: - Empty Block

    /// Builds an empty block into an EmptyView, matching SwiftUI.
    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    // MARK: - Single View

    /// Builds a single view.
    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    // MARK: - Multiple Views (Parameter Pack)

    /// Builds multiple views into a tuple-typed TupleView, matching SwiftUI's
    /// `TupleView<(repeat each Content)>` result shape.
    ///
    /// The children are captured alongside the tuple so rendering does not
    /// need to reflect over the tuple value.
    public static func buildBlock<each Content: View>(
        _ content: repeat each Content
    ) -> TupleView<(repeat each Content)> {
        var children: [any View] = []
        repeat children.append(each content)
        return TupleView(value: (repeat each content), children: children)
    }

    // MARK: - Conditionals

    /// Supports the true branch of an if-else.
    public static func buildEither<TrueContent: View, FalseContent: View>(
        first content: TrueContent
    ) -> _ConditionalContent<TrueContent, FalseContent> {
        .trueContent(content)
    }

    /// Supports the false branch of an if-else.
    public static func buildEither<TrueContent: View, FalseContent: View>(
        second content: FalseContent
    ) -> _ConditionalContent<TrueContent, FalseContent> {
        .falseContent(content)
    }

    /// Supports optional views (if let, if without else), matching SwiftUI's
    /// `buildIf` spelling.
    public static func buildIf<Content: View>(_ content: Content?) -> Content? {
        content
    }

    /// Supports availability limiting.
    ///
    /// The branch content is erased to ``AnyView`` because the enclosing
    /// builder block cannot name types that are only available inside the
    /// `#available` branch. This matches SwiftUI's result shape.
    public static func buildLimitedAvailability<Content: View>(_ content: Content) -> AnyView {
        AnyView(content)
    }

    // MARK: - Arrays

    /// Supports for-in loops.
    ///
    /// SwiftUI's `ViewBuilder` has no array support (`ForEach` covers
    /// iteration); TUIkit keeps this as a documented additive convenience.
    public static func buildArray<Content: View>(_ components: [Content]) -> ViewArray<Content> {
        ViewArray(components)
    }

    // MARK: - Expression

    /// Converts a single expression into a view.
    public static func buildExpression<Content: View>(_ expression: Content) -> Content {
        expression
    }
}
