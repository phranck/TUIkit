//
//  View+Padding.swift
//  TUIKit
//
//  The .padding() view extensions for adding space around views.
//

extension View {
    /// Adds padding on all sides.
    ///
    /// ```swift
    /// Text("Hello")
    ///     .padding(2)
    /// ```
    ///
    /// - Parameter amount: The padding amount on all sides (default: 1).
    /// - Returns: A padded view.
    public func padding(_ amount: Int = 1) -> ModifiedView<Self, PaddingModifier> {
        modifier(PaddingModifier(insets: EdgeInsets(all: amount)))
    }

    /// Adds padding on specific edges.
    ///
    /// ```swift
    /// Text("Hello")
    ///     .padding(.horizontal, 4)
    /// ```
    ///
    /// - Parameters:
    ///   - edges: The edges to pad.
    ///   - amount: The padding amount (default: 1).
    /// - Returns: A padded view.
    public func padding(_ edges: Edge, _ amount: Int = 1) -> ModifiedView<Self, PaddingModifier> {
        let insets = EdgeInsets(
            top: edges.contains(.top) ? amount : 0,
            leading: edges.contains(.leading) ? amount : 0,
            bottom: edges.contains(.bottom) ? amount : 0,
            trailing: edges.contains(.trailing) ? amount : 0
        )
        return modifier(PaddingModifier(insets: insets))
    }

    /// Adds padding with explicit edge insets.
    ///
    /// ```swift
    /// Text("Hello")
    ///     .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
    /// ```
    ///
    /// - Parameter insets: The edge insets.
    /// - Returns: A padded view.
    public func padding(_ insets: EdgeInsets) -> ModifiedView<Self, PaddingModifier> {
        modifier(PaddingModifier(insets: insets))
    }
}
