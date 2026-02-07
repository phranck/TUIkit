//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TupleViews.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A view that contains multiple child views packed via a parameter pack.
///
/// `TupleView` replaces the previous `TupleView2` through `TupleView10`
/// types with a single generic struct using Swift Parameter Packs (SE-0393).
/// This removes the 10-child limit and eliminates ~400 lines of boilerplate.
///
/// `TupleView` is created automatically by `ViewBuilder` when multiple
/// views appear in a `@ViewBuilder` closure.
///
/// - Important: This is framework infrastructure. Created automatically by
///   `@ViewBuilder`. Do not instantiate directly.
public struct TupleView<each V: View>: View {
    /// The packed child views.
    let children: (repeat each V)

    /// Creates a tuple view from a parameter pack of child views.
    ///
    /// - Parameter children: The child views.
    init(_ children: repeat each V) {
        self.children = (repeat each children)
    }

    public var body: Never {
        fatalError("TupleView renders its children directly")
    }
}

// MARK: - Equatable Conformance

extension TupleView: @preconcurrency Equatable where repeat each V: Equatable {
    public static func == (lhs: TupleView, rhs: TupleView) -> Bool {
        func isEqual<T: Equatable>(_ left: T, _ right: T) -> Bool { left == right }
        var result = true
        repeat result = result && isEqual(each lhs.children, each rhs.children)
        return result
    }
}

// MARK: - TupleView Rendering + ChildInfoProvider

extension TupleView: Renderable, ChildInfoProvider {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(verticallyStacking: childInfos(context: context).compactMap(\.buffer))
    }

    func childInfos(context: RenderContext) -> [ChildInfo] {
        var infos: [ChildInfo] = []
        repeat infos.append(
            makeChildInfo(
                for: each children,
                context: context.withChildIdentity(type: type(of: each children), index: infos.count)
            )
        )
        return infos
    }
}
