//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PrimitiveViews.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore
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
public struct EmptyView: View, Equatable {
    /// Creates an empty view.
    public init() {}

    public var body: Never {
        fatalError("EmptyView has no body")
    }
}

// MARK: - _ConditionalContent

/// A view that represents either the true or false branch of a conditional.
///
/// This type is used internally by `ViewBuilder` for if-else statements.
///
/// - Important: This is framework infrastructure. Created automatically by
///   `@ViewBuilder` for `if`/`else` branches. Do not instantiate directly.
public enum _ConditionalContent<TrueContent: View, FalseContent: View>: View {
    /// The true branch was executed.
    case trueContent(TrueContent)

    /// The false branch was executed.
    case falseContent(FalseContent)

    public var body: Never {
        fatalError("_ConditionalContent renders its children directly")
    }
}

// MARK: - ViewArray

/// A view that contains an array of identical views.
///
/// This type is used internally by `ViewBuilder` for for-in loops.
///
/// ```swift
/// for item in items {
///     Text(item.name)
/// }
/// ```
///
/// - Important: This is framework infrastructure. Created automatically by
///   `@ViewBuilder` for array content. Do not instantiate directly.
public struct ViewArray<Element: View>: View {
    /// The contained views.
    let elements: [Element]

    /// Creates a ViewArray from an array of views.
    ///
    /// - Parameter elements: The views this container holds.
    public init(_ elements: [Element]) {
        self.elements = elements
    }

    public var body: Never {
        fatalError("ViewArray renders its children directly")
    }
}

// MARK: - AnyView

/// A type-erased view for conditional returns.
///
/// Use `AnyView` when you need to return different view types
/// from a conditional expression.
///
/// ```swift
/// func content(showDetail: Bool) -> AnyView {
///     if showDetail {
///         return AnyView(DetailView())
///     } else {
///         return AnyView(SummaryView())
///     }
/// }
/// ```
public struct AnyView: View {
    private let _render: (RenderContext) -> FrameBuffer

    /// Creates an AnyView wrapping the given view.
    ///
    /// - Parameter view: The view to type-erase.
    public init<V: View>(_ view: V) {
        self._render = { context in
            TUIkitView.renderToBuffer(view, context: context)
        }
    }

    /// Creates an AnyView wrapping the given view, matching SwiftUI's
    /// labeled erasure initializer.
    ///
    /// - Parameter view: The view to type-erase.
    public init<V: View>(erasing view: V) {
        self.init(view)
    }

    public var body: Never {
        fatalError("AnyView renders via Renderable")
    }
}

// MARK: - AnyView Rendering

extension AnyView: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        _render(context)
    }
}

// MARK: - EmptyView Rendering

extension EmptyView: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer()
    }
}

// MARK: - _ConditionalContent Rendering

extension _ConditionalContent: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let stateStorage = context.environment.stateStorage!
        switch self {
        case .trueContent(let content):
            stateStorage.invalidateDescendants(of: context.identity.branch("false"))
            return TUIkitView.renderToBuffer(content, context: context.withBranchIdentity("true"))
        case .falseContent(let content):
            stateStorage.invalidateDescendants(of: context.identity.branch("true"))
            return TUIkitView.renderToBuffer(content, context: context.withBranchIdentity("false"))
        }
    }
}

// MARK: - _ConditionalContent Child Traversal

extension _ConditionalContent: ChildInfoProvider, ChildViewProvider {
    public func childInfos(context: RenderContext) -> [ChildInfo] {
        switch self {
        case .trueContent(let content):
            invalidateInactiveBranch("false", context: context)
            return resolveChildInfos(from: content, context: context.withBranchIdentity("true"))
        case .falseContent(let content):
            invalidateInactiveBranch("true", context: context)
            return resolveChildInfos(from: content, context: context.withBranchIdentity("false"))
        }
    }

    public func childViews(context: RenderContext) -> [ChildView] {
        switch self {
        case .trueContent(let content):
            invalidateInactiveBranch("false", context: context)
            return scopedChildViews(from: content, branch: "true", context: context)
        case .falseContent(let content):
            invalidateInactiveBranch("true", context: context)
            return scopedChildViews(from: content, branch: "false", context: context)
        }
    }

    private func invalidateInactiveBranch(_ branch: String, context: RenderContext) {
        context.environment.stateStorage?.invalidateDescendants(of: context.identity.branch(branch))
    }

    private func scopedChildViews<Content: View>(
        from content: Content,
        branch: String,
        context: RenderContext
    ) -> [ChildView] {
        let branchContext = context.withBranchIdentity(branch)
        return resolveChildViews(from: content, context: branchContext).map {
            $0.scoped(to: branchContext.identity)
        }
    }
}

// MARK: - ViewArray Rendering

extension ViewArray: Renderable, ChildInfoProvider, ChildViewProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    public func childInfos(context: RenderContext) -> [ChildInfo] {
        elements.enumerated().flatMap { index, element in
            let childContext = context.withChildIdentity(type: Element.self, index: index)
            return resolveChildInfos(from: element, context: childContext)
        }
    }

    public func childViews(context: RenderContext) -> [ChildView] {
        elements.enumerated().flatMap { index, element in
            guard let provider = element as? ChildViewProvider else {
                return [ChildView(element, childIndex: index)]
            }

            let childContext = context.withChildIdentity(type: Element.self, index: index)
            return provider.childViews(context: childContext).map {
                $0.scoped(to: childContext.identity)
            }
        }
    }
}
