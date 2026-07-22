//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TupleViews.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

/// A view that contains multiple child views packed into a tuple.
///
/// `TupleView` matches SwiftUI's public shape: it is generic over one tuple
/// type `T` and exposes the packed children through ``value``. It is created
/// automatically by `ViewBuilder` when multiple views appear in a
/// `@ViewBuilder` closure.
///
/// ## Child resolution
///
/// Rendering needs the individual children, not the tuple. Builder-created
/// instances capture the children directly from the parameter pack (no
/// reflection cost). Instances created through the public initializer resolve
/// children by reflecting over the tuple at render time.
///
/// - Important: This is framework infrastructure. Created automatically by
///   `@ViewBuilder`. Do not instantiate directly.
public struct TupleView<T>: View {
    /// The packed child views.
    public var value: T

    /// Children captured from the builder's parameter pack.
    ///
    /// `nil` for publicly constructed instances, which resolve children by
    /// reflection instead. Builder instances are recreated every frame, so
    /// the captured array cannot go stale.
    private let packedChildren: [any View]?

    /// Creates a tuple view from a tuple of child views.
    ///
    /// - Parameter value: The tuple containing the child views.
    public init(_ value: T) {
        self.value = value
        self.packedChildren = nil
    }

    /// Builder fast path carrying the statically known children.
    ///
    /// - Parameters:
    ///   - value: The tuple containing the child views.
    ///   - children: The children in declaration order.
    init(value: T, children: [any View]) {
        self.value = value
        self.packedChildren = children
    }

    public var body: Never {
        fatalError("TupleView renders its children directly")
    }
}

// MARK: - Child Resolution

extension TupleView {
    /// Returns the child views in declaration order.
    ///
    /// Uses the builder-captured children when available and falls back to
    /// reflecting over the tuple for publicly constructed instances. Non-view
    /// tuple elements are ignored.
    package func resolvedChildren() -> [any View] {
        if let packedChildren {
            return packedChildren
        }
        if let single = value as? any View {
            return [single]
        }
        return Mirror(reflecting: value).children.compactMap { $0.value as? any View }
    }
}

// MARK: - Equatable Conformance

/// Compares two type-erased views for equality.
///
/// Views that do not conform to `Equatable` never compare as equal. This is
/// the safe direction for subtree memoization: an unequal comparison causes a
/// cache miss and a fresh render instead of stale output.
private func anyViewsEqual(_ lhs: any View, _ rhs: any View) -> Bool {
    guard let comparable = lhs as? any Equatable else { return false }
    return openedEqual(comparable, rhs)
}

/// Opens the `Equatable` existential and compares both values as `E`.
private func openedEqual<E: Equatable>(_ lhs: E, _ rhs: Any) -> Bool {
    guard let typed = rhs as? E else { return false }
    return lhs == typed
}

extension TupleView: @preconcurrency Equatable {
    /// Element-wise best-effort equality over the packed children.
    ///
    /// SwiftUI's `TupleView` declares no `Equatable` conformance; TUIkit adds
    /// this one so `.equatable()` keeps working on multi-child containers
    /// (Swift 6.0 cannot express conditional conformance over tuple
    /// elements). Children without `Equatable` conformance make the whole
    /// comparison unequal, which safely degrades to a cache miss.
    public static func == (lhs: TupleView, rhs: TupleView) -> Bool {
        let leftChildren = lhs.resolvedChildren()
        let rightChildren = rhs.resolvedChildren()
        guard leftChildren.count == rightChildren.count else { return false }
        return zip(leftChildren, rightChildren).allSatisfy(anyViewsEqual)
    }
}

// MARK: - TupleView Rendering + ChildInfoProvider

extension TupleView: Renderable, ChildInfoProvider {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    public func childInfos(context: RenderContext) -> [ChildInfo] {
        var infos: [ChildInfo] = []
        for (index, child) in resolvedChildren().enumerated() {
            infos.append(contentsOf: childInfos(for: child, index: index, context: context))
        }
        return infos
    }

    /// Resolves one child's infos with its opened concrete type.
    private func childInfos<Child: View>(
        for child: Child,
        index: Int,
        context: RenderContext
    ) -> [ChildInfo] {
        let childContext = context.withChildIdentity(type: Child.self, index: index)
        return resolveChildInfos(from: child, context: childContext)
    }
}

// MARK: - TupleView Two-Pass Layout Support

extension TupleView: ChildViewProvider {
    public func childViews(context: RenderContext) -> [ChildView] {
        var views: [ChildView] = []
        for (index, child) in resolvedChildren().enumerated() {
            views.append(contentsOf: childViews(for: child, index: index, context: context))
        }
        return views
    }

    /// Resolves one child's layout views with its opened concrete type.
    private func childViews<Child: View>(
        for child: Child,
        index: Int,
        context: RenderContext
    ) -> [ChildView] {
        if let provider = child as? ChildViewProvider {
            let childContext = context.withChildIdentity(type: Child.self, index: index)
            return provider.childViews(context: childContext).map {
                $0.scoped(to: childContext.identity)
            }
        }
        return [ChildView(child, childIndex: index)]
    }
}
