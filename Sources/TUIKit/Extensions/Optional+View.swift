//
//  Optional+View.swift
//  TUIKit
//
//  Optional conformance to View when the wrapped type conforms to View.
//

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
