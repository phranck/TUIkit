//
//  Scene.swift
//  TUIKit
//
//  Scene types for TUIKit applications.
//

/// The base protocol for scenes in TUIKit.
///
/// A scene represents a part of the app structure,
/// typically a window or a group of views.
public protocol Scene {}

// MARK: - WindowGroup

/// A scene that represents a single window (terminal).
///
/// `WindowGroup` is the main scene for most TUI apps.
///
/// # Example
///
/// ```swift
/// WindowGroup {
///     ContentView()
/// }
/// ```
public struct WindowGroup<Content: View>: Scene {
    /// The content of the window.
    public let content: Content

    /// Creates a WindowGroup with the specified content.
    ///
    /// - Parameter content: A ViewBuilder that defines the content.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
}

// MARK: - SceneBuilder

/// A result builder for scene hierarchies.
@resultBuilder
public struct SceneBuilder {
    /// Builds a single scene.
    public static func buildBlock<Content: Scene>(_ content: Content) -> Content {
        content
    }
}
