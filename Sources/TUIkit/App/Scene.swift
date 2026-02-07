//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Scene.swift
//
//  Created by LAYERED.work
//  License: MIT

/// The base protocol for scenes in TUIKit.
///
/// A scene represents a distinct region of the app's user interface,
/// analogous to SwiftUI's `Scene` protocol. In TUIKit, scenes define
/// the top-level structure of your terminal application.
///
/// ## Overview
///
/// Scenes sit between the ``App`` and ``View`` layers in TUIKit's
/// architecture. While views define the content, scenes define how
/// that content is organized at the application level.
///
/// Currently, TUIKit provides one scene type:
/// - ``WindowGroup``: Displays content in the terminal window
///
/// ## Conforming to Scene
///
/// You typically don't create custom scene types. Instead, use the
/// built-in ``WindowGroup`` in your app's `body`:
///
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Built-in Scenes
/// - ``WindowGroup``
@MainActor
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

/// A result builder that constructs scene hierarchies from closures.
///
/// `SceneBuilder` enables the declarative syntax used in ``App/body-swift.property``
/// to define your application's scene structure. You don't use this type directly;
/// instead, the `@SceneBuilder` attribute is applied to the `body` property of
/// your ``App`` conforming type.
///
/// ## Overview
///
/// When you write:
///
/// ```swift
/// var body: some Scene {
///     WindowGroup {
///         ContentView()
///     }
/// }
/// ```
///
/// The `@SceneBuilder` attribute transforms this closure into a scene that
/// TUIKit can render. Currently, `SceneBuilder` supports a single scene
/// in the body, which is typically a ``WindowGroup``.
@MainActor
@resultBuilder
public struct SceneBuilder {
    /// Builds a scene expression from a single scene component.
    ///
    /// - Parameter content: The scene to build.
    /// - Returns: The same scene, unchanged.
    public static func buildBlock<Content: Scene>(_ content: Content) -> Content {
        content
    }
}
