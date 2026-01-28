//
//  PrimitiveViews.swift
//  SwiftTUI
//
//  Primitive view types that serve as leaves in the view tree.
//

// MARK: - Never as TView

/// `Never` conforms to TView for views that have no body.
///
/// Primitive views like `Text` or containers like `TupleView` have no
/// body of their own - they are rendered directly. This extension allows
/// using `Never` as the body type.
extension Never: TView {
    public var body: Never {
        fatalError("Never.body should never be called")
    }
}

// MARK: - EmptyView

/// A view that displays no content.
///
/// `EmptyView` is useful for placeholders or when a view
/// should display nothing under certain conditions.
///
/// ```swift
/// if showContent {
///     Text("Content")
/// } else {
///     EmptyView()
/// }
/// ```
public struct EmptyView: TView {
    /// Creates an empty view.
    public init() {}

    public var body: Never {
        fatalError("EmptyView has no body")
    }
}

// MARK: - ConditionalView

/// A view that represents either the true or false branch of a conditional.
///
/// This type is used internally by `TViewBuilder` for if-else statements.
public enum ConditionalView<TrueContent: TView, FalseContent: TView>: TView {
    /// The true branch was executed.
    case trueContent(TrueContent)

    /// The false branch was executed.
    case falseContent(FalseContent)

    public var body: Never {
        fatalError("ConditionalView renders its children directly")
    }
}

// MARK: - TViewArray

/// A view that contains an array of identical views.
///
/// This type is used internally by `TViewBuilder` for for-in loops.
///
/// ```swift
/// ForEach(items) { item in
///     Text(item.name)
/// }
/// ```
public struct TViewArray<Element: TView>: TView {
    /// The contained views.
    public let elements: [Element]

    /// Creates a TViewArray from an array of views.
    ///
    /// - Parameter elements: The views this container holds.
    public init(_ elements: [Element]) {
        self.elements = elements
    }

    public var body: Never {
        fatalError("TViewArray renders its children directly")
    }
}

// MARK: - Optional TView Conformance

/// Optional views conform to TView when their Wrapped type does.
extension Optional: TView where Wrapped: TView {
    public var body: some TView {
        switch self {
        case .some(let view):
            view
        case .none:
            EmptyView()
        }
    }
}
