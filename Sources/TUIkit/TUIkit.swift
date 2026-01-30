//
//  TUIkit.swift
//  TUIkit
//
//  A SwiftUI-like framework for Terminal User Interfaces.
//
//  TUIkit enables creating TUI applications with a declarative,
//  SwiftUI-like syntax - without ncurses or other low-level libraries.
//

/// The current version of TUIkit.
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
///         Text("Hello, TUIkit!")
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
/// Renders a view hierarchy once and prints the result to standard output.
///
/// This is useful for simple CLI tools that don't need a full App lifecycle.
///
/// - Parameter content: A ViewBuilder closure that defines the view to render.
public func renderOnce<Content: View>(@ViewBuilder content: () -> Content) {
    let view = content()
    let renderer = ViewRenderer()
    renderer.render(view)
}
