//
//  TView.swift
//  SwiftTUI
//
//  The base protocol for all SwiftTUI views.
//

/// The base protocol for all SwiftTUI views.
///
/// `TView` is the central protocol in SwiftTUI and works similarly to `View` in SwiftUI.
/// It defines how components declare their structure and content.
///
/// Every TView defines a `body` composed of other TViews.
/// This enables a hierarchical, declarative UI description.
///
/// # Example
///
/// ```swift
/// struct MyView: TView {
///     var body: some TView {
///         Text("Hello, SwiftTUI!")
///     }
/// }
/// ```
public protocol TView {
    /// The type of the body view.
    ///
    /// Swift automatically infers this type from the `body` implementation.
    associatedtype Body: TView

    /// The content and behavior of this view.
    ///
    /// Implement this property to define the structure of your view.
    /// The body consists of other TViews that together form the UI.
    @TViewBuilder
    var body: Body { get }
}
