//
//  View.swift
//  TUIKit
//
//  The base protocol for all TUIKit views.
//

/// The base protocol for all TUIKit views.
///
/// `View` is the central protocol in TUIKit and works similarly to `View` in SwiftUI.
/// It defines how components declare their structure and content.
///
/// Every View defines a `body` composed of other Views.
/// This enables a hierarchical, declarative UI description.
///
/// # Example
///
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         Text("Hello, TUIKit!")
///     }
/// }
/// ```
public protocol View {
    /// The type of the body view.
    ///
    /// Swift automatically infers this type from the `body` implementation.
    associatedtype Body: View

    /// The content and behavior of this view.
    ///
    /// Implement this property to define the structure of your view.
    /// The body consists of other Views that together form the UI.
    @ViewBuilder
    var body: Body { get }
}
