//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PrimitiveTypes+View.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore
// MARK: - Never as View

/// `Never` conforms to View for views that have no body.
///
/// Primitive views like `Text` or containers like `TupleView` have no
/// body of their own - they are rendered directly. This extension allows
/// using `Never` as the body type.
extension Never: View {
    public var body: Never {
        fatalError("Never.body should never be called")
    }
}

// MARK: - Optional View Conformance

/// Optional views conform to View when their Wrapped type does.
extension Optional: View where Wrapped: View {
    public var body: some View {
        switch self {
        case .some(let view):
            view
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Optional Rendering

extension Optional: Renderable where Wrapped: View {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        switch self {
        case .some(let view):
            return TUIkitView.renderToBuffer(view, context: context)
        case .none:
            return FrameBuffer()
        }
    }
}
