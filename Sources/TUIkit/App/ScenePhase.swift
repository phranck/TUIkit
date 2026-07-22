//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ScenePhase.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - Scene Phase

/// An indication of a scene's operational state.
///
/// A terminal session has exactly one scene: it is ``active`` while the
/// runtime owns the terminal and processes events. The ``inactive`` and
/// ``background`` phases exist for SwiftUI compatibility and future
/// suspension semantics; multiwindow phase transitions have no terminal
/// meaning. Phase-driven actions (`onChange(of: scenePhase)`) arrive with
/// the application-actions work (#33).
public enum ScenePhase: Comparable, Hashable, Sendable {
    /// The scene is not currently visible.
    case background

    /// The scene is visible but not responding to input.
    case inactive

    /// The scene is visible and responding to input.
    case active
}

// MARK: - Environment Key

/// Environment key carrying the current scene phase.
private struct ScenePhaseKey: EnvironmentKey {
    static let defaultValue: ScenePhase = .active
}

extension EnvironmentValues {
    /// The current operational phase of the scene.
    public var scenePhase: ScenePhase {
        get { self[ScenePhaseKey.self] }
        set { self[ScenePhaseKey.self] = newValue }
    }
}
