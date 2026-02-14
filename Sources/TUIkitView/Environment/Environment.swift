//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Environment.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - Environment Modifier

/// A modifier that injects a value into the environment for child views.
///
/// `EnvironmentModifier` conforms to both `View` and ``Renderable``.
/// Because ``renderToBuffer(_:context:)`` checks `Renderable` first,
/// the `body` property below is **never called during rendering**.
/// It exists only to satisfy the `View` protocol requirement.
/// All actual work happens in `renderToBuffer(context:)`.
public struct EnvironmentModifier<Content: View, V>: View {
    /// The content view.
    public let content: Content

    /// The key path to modify.
    public let keyPath: WritableKeyPath<EnvironmentValues, V>

    /// The value to inject.
    public let value: V


    /// Creates a new environment modifier.
    public init(content: Content, keyPath: WritableKeyPath<EnvironmentValues, V>, value: V) {
        self.content = content
        self.keyPath = keyPath
        self.value = value
    }
    /// Not used during rendering — ``Renderable`` conformance takes priority.
    public var body: some View {
        content
    }
}

extension EnvironmentModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Create modified environment and render content with it.
        // The modified context carries the environment through the render tree —
        // no global state sync needed.
        let modifiedEnvironment = context.environment.setting(keyPath, to: value)
        let modifiedContext = context.withEnvironment(modifiedEnvironment)
        return TUIkitView.renderToBuffer(content, context: modifiedContext)
    }
}
