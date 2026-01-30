//
//  Optional+Renderable.swift
//  TUIKit
//
//  Optional conformance to Renderable when the wrapped type conforms to View.
//

// MARK: - Optional Rendering

extension Optional: Renderable where Wrapped: View {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        switch self {
        case .some(let view):
            return TUIKit.renderToBuffer(view, context: context)
        case .none:
            return FrameBuffer()
        }
    }
}
