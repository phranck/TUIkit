//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewServiceEnvironment.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - State Storage

/// EnvironmentKey for the persistent `@State` value storage.
private struct StateStorageKey: EnvironmentKey {
    static let defaultValue: StateStorage? = nil
}

// MARK: - Render Cache

/// EnvironmentKey for memoized subtree rendering results.
private struct RenderCacheKey: EnvironmentKey {
    static let defaultValue: RenderCache? = nil
}

// MARK: - EnvironmentValues Extensions

extension EnvironmentValues {

    /// The persistent `@State` value storage indexed by `ViewIdentity`.
    public var stateStorage: StateStorage? {
        get { self[StateStorageKey.self] }
        set { self[StateStorageKey.self] = newValue }
    }

    /// Cache for memoized subtree rendering results.
    public var renderCache: RenderCache? {
        get { self[RenderCacheKey.self] }
        set { self[RenderCacheKey.self] = newValue }
    }
}
