//
//  View+AnyView.swift
//  TUIKit
//
//  The .asAnyView() view extension for type erasure.
//

extension View {
    /// Wraps this view in an AnyView for type erasure.
    ///
    /// Use this when you need to return different view types from
    /// conditional branches.
    public func asAnyView() -> AnyView {
        AnyView(self)
    }
}
