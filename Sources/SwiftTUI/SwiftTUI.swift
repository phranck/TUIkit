//
//  SwiftTUI.swift
//  SwiftTUI
//
//  A SwiftUI-like framework for Terminal User Interfaces.
//
//  SwiftTUI enables creating TUI applications with a declarative,
//  SwiftUI-like syntax - without ncurses or other low-level libraries.
//

/// The current version of SwiftTUI.
public let swiftTUIVersion = "0.1.0"

/// Executes a view closure and renders it once.
///
/// This is useful for simple CLI tools that don't need a full TApp.
///
/// # Example
///
/// ```swift
/// renderOnce {
///     VStack {
///         Text("Hello, SwiftTUI!")
///             .bold()
///             .foregroundColor(.cyan)
///         Divider()
///         Text("Version \(swiftTUIVersion)")
///             .dim()
///     }
/// }
/// ```
///
/// - Parameter content: A ViewBuilder closure that defines the view to render.
@discardableResult
public func renderOnce<Content: TView>(@TViewBuilder content: () -> Content) -> Int {
    let view = content()
    let renderer = ViewRenderer()
    renderer.render(view)
    return 0 // TODO: Return actual line count
}
