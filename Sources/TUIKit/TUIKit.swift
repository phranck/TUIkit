//
//  TUIKit.swift
//  TUIKit
//
//  A SwiftUI-like framework for Terminal User Interfaces.
//
//  TUIKit enables creating TUI applications with a declarative,
//  SwiftUI-like syntax - without ncurses or other low-level libraries.
//

/// The current version of TUIKit.
public let tuiKitVersion = "0.1.0"

/// Executes a view closure and renders it once.
///
/// This is useful for simple CLI tools that don't need a full App.
///
/// # Example
///
/// ```swift
/// renderOnce {
///     VStack {
///         Text("Hello, TUIKit!")
///             .bold()
///             .foregroundColor(.cyan)
///         Divider()
///         Text("Version \(tuiKitVersion)")
///             .dim()
///     }
/// }
/// ```
///
/// - Parameter content: A ViewBuilder closure that defines the view to render.
@discardableResult
public func renderOnce<Content: View>(@ViewBuilder content: () -> Content) -> Int {
    let view = content()
    let renderer = ViewRenderer()
    renderer.render(view)
    return 0 // TODO: Return actual line count
}
