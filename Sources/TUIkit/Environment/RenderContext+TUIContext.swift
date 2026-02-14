//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderContext+TUIContext.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore
import TUIkitView

// MARK: - TUIContext Integration

extension RenderContext {
    /// Creates a new RenderContext with runtime services from a `TUIContext`.
    ///
    /// Injects all services from the `TUIContext` into `EnvironmentValues`,
    /// making them accessible via `context.environment.stateStorage`, etc.
    ///
    /// - Parameters:
    ///   - availableWidth: The available width in characters.
    ///   - availableHeight: The available height in lines.
    ///   - environment: The environment values (defaults to empty).
    ///   - tuiContext: The TUI context whose services are injected into the environment.
    ///   - identity: The view identity path (defaults to root).
    init(
        availableWidth: Int,
        availableHeight: Int,
        environment: EnvironmentValues = EnvironmentValues(),
        tuiContext: TUIContext,
        identity: ViewIdentity = ViewIdentity(path: "")
    ) {
        var env = environment
        env.stateStorage = tuiContext.stateStorage
        env.lifecycle = tuiContext.lifecycle
        env.keyEventDispatcher = tuiContext.keyEventDispatcher
        env.renderCache = tuiContext.renderCache
        env.preferenceStorage = tuiContext.preferences
        self.init(
            availableWidth: availableWidth,
            availableHeight: availableHeight,
            environment: env,
            identity: identity
        )
    }

    /// Creates a context isolated from the real focus and key event systems.
    ///
    /// Used by modal presentation modifiers to render background content
    /// visually without letting its buttons and key handlers interfere
    /// with the modal's interactive elements. The returned context has a
    /// throwaway `FocusManager` and `KeyEventDispatcher` while sharing
    /// lifecycle, preferences, and state storage with the real context.
    func isolatedForBackground() -> Self {
        var copy = self
        copy.environment.focusManager = FocusManager()
        copy.environment.keyEventDispatcher = KeyEventDispatcher()
        return copy
    }
}
