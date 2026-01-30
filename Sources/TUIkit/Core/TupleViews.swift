//
//  TupleViews.swift
//  TUIkit
//
//  Container type for multiple views in ViewBuilder, using Swift Parameter Packs.
//

/// A view that contains multiple child views packed via a parameter pack.
///
/// `TupleView` replaces the previous `TupleView2` through `TupleView10`
/// types with a single generic struct using Swift Parameter Packs (SE-0393).
/// This removes the 10-child limit and eliminates ~400 lines of boilerplate.
///
/// `TupleView` is created automatically by `ViewBuilder` when multiple
/// views appear in a `@ViewBuilder` closure.
public struct TupleView<each V: View>: View {
    /// The packed child views.
    public let children: (repeat each V)

    /// Creates a tuple view from a parameter pack of child views.
    ///
    /// - Parameter children: The child views.
    public init(_ children: repeat each V) {
        self.children = (repeat each children)
    }

    public var body: Never {
        fatalError("TupleView renders its children directly")
    }
}
