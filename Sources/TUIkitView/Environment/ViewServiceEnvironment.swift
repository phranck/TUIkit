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

// MARK: - Render Invalidation

/// EnvironmentKey for routing state changes to the owning runtime.
private struct RenderInvalidationSinkKey: EnvironmentKey {
    static let defaultValue: (any RenderInvalidationSink)? = nil
}

// MARK: - Observation Registry

/// EnvironmentKey for identity-bound Observation registrations.
private struct ObservationRegistryKey: EnvironmentKey {
    static let defaultValue: ObservationRegistry? = nil
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

    /// Sink that routes state changes to the runtime owning this render tree.
    public var renderInvalidationSink: (any RenderInvalidationSink)? {
        get { self[RenderInvalidationSinkKey.self] }
        set { self[RenderInvalidationSinkKey.self] = newValue }
    }

    /// Registry that binds Observation callbacks to structural identities.
    package var observationRegistry: ObservationRegistry? {
        get { self[ObservationRegistryKey.self] }
        set { self[ObservationRegistryKey.self] = newValue }
    }
}
