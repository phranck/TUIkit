//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Scene+Environment.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Environment-Modified Scene

/// A scene wrapping another scene with an environment transform.
///
/// Scene modifiers compose by nesting these wrappers; ``SceneResolution``
/// unwinds the chain outside-in when the runtime resolves the frame's
/// environment. This layer is also the extension point for future
/// scene-level configuration (commands, app-wide actions).
struct EnvironmentModifiedScene<Content: Scene>: Scene {
    /// The wrapped scene.
    let content: Content

    /// The environment mutation this modifier applies.
    let transform: (inout EnvironmentValues) -> Void

    /// Never called — rendering runs through the internal scene pipeline.
    var body: Never {
        fatalError("EnvironmentModifiedScene renders via SceneResolution")
    }
}

// MARK: - Type-Erased Traversal

/// Type-erased access used by ``SceneResolution`` to unwind modifier chains.
@MainActor
private protocol EnvironmentTransformingScene {
    /// The environment mutation to apply at this level.
    var anyTransform: (inout EnvironmentValues) -> Void { get }

    /// The scene wrapped by this modifier.
    var anyContent: any Scene { get }
}

extension EnvironmentModifiedScene: EnvironmentTransformingScene {
    fileprivate var anyTransform: (inout EnvironmentValues) -> Void { transform }
    fileprivate var anyContent: any Scene { content }
}

// MARK: - Scene Resolution

/// Resolves a scene hierarchy into its renderable core and environment.
///
/// Modifier wrappers are unwound outside-in: outer transforms apply first,
/// so inner (closer to the window) values win on duplicate keys — matching
/// view-environment semantics.
@MainActor
enum SceneResolution {
    /// Unwinds scene modifiers into the environment and returns the
    /// renderable core scene.
    ///
    /// - Parameters:
    ///   - scene: The scene returned by `App.body`.
    ///   - environment: The frame environment receiving scene values.
    /// - Returns: The renderable core, or `nil` for non-renderable scenes.
    static func resolve(
        _ scene: any Scene,
        applyingTo environment: inout EnvironmentValues
    ) -> (any SceneRenderable)? {
        var current: any Scene = scene

        while let modifier = current as? any EnvironmentTransformingScene {
            modifier.anyTransform(&environment)
            current = modifier.anyContent
        }

        return current as? any SceneRenderable
    }
}

// MARK: - Scene Environment Modifiers

extension Scene {
    /// Sets an environment value for all views in this scene.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the environment value to set.
    ///   - value: The value to inject.
    /// - Returns: A scene with the modified environment.
    public func environment<V>(
        _ keyPath: WritableKeyPath<EnvironmentValues, V>,
        _ value: V
    ) -> some Scene {
        EnvironmentModifiedScene(content: self) { environment in
            environment[keyPath: keyPath] = value
        }
    }

    /// Applies a color palette to all views in this scene.
    ///
    /// This is the scene-level counterpart of the view modifier, so the
    /// documented `WindowGroup { … }.palette(…)` shape works and also aligns
    /// out-of-tree surfaces (status bar, app header):
    ///
    /// ```swift
    /// WindowGroup {
    ///     ContentView()
    /// }
    /// .palette(SystemPalette(.amber))
    /// ```
    ///
    /// - Parameter palette: The palette to apply.
    /// - Returns: A scene with the palette applied.
    public func palette(_ palette: any Palette) -> some Scene {
        environment(\.palette, palette)
    }

    /// Applies a border appearance to all views in this scene.
    ///
    /// - Parameter appearance: The appearance to apply.
    /// - Returns: A scene with the appearance applied.
    public func appearance(_ appearance: Appearance) -> some Scene {
        environment(\.appearance, appearance)
    }
}
