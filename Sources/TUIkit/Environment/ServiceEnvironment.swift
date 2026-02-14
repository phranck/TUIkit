//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ServiceEnvironment.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - State Storage

/// EnvironmentKey for the persistent `@State` value storage.
private struct StateStorageKey: EnvironmentKey {
    static let defaultValue: StateStorage? = nil
}

// MARK: - Lifecycle Manager

/// EnvironmentKey for view lifecycle tracking (appear/disappear/task).
private struct LifecycleKey: EnvironmentKey {
    static let defaultValue: LifecycleManager? = nil
}

// MARK: - Key Event Dispatcher

/// EnvironmentKey for key event handler registration and dispatch.
private struct KeyEventDispatcherKey: EnvironmentKey {
    static let defaultValue: KeyEventDispatcher? = nil
}

// MARK: - Render Cache

/// EnvironmentKey for memoized subtree rendering results.
private struct RenderCacheKey: EnvironmentKey {
    static let defaultValue: RenderCache? = nil
}

// MARK: - Preference Storage

/// EnvironmentKey for preference value collection during rendering.
private struct PreferenceStorageKey: EnvironmentKey {
    static let defaultValue: PreferenceStorage? = nil
}

// MARK: - Pulse Phase

/// EnvironmentKey for the focus indicator breathing animation phase.
private struct PulsePhaseKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

// MARK: - Cursor Timer

/// EnvironmentKey for TextField/SecureField cursor blink animation.
private struct CursorTimerKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: CursorTimer? = nil
}

// MARK: - Focus Indicator Color

/// EnvironmentKey for the focus indicator color in the current subtree.
private struct FocusIndicatorColorKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

// MARK: - Active Focus Section

/// EnvironmentKey for the focus section that child views should register in.
private struct ActiveFocusSectionKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

// MARK: - EnvironmentValues Extensions

extension EnvironmentValues {

    /// The persistent `@State` value storage indexed by `ViewIdentity`.
    var stateStorage: StateStorage? {
        get { self[StateStorageKey.self] }
        set { self[StateStorageKey.self] = newValue }
    }

    /// View lifecycle tracking (appear, disappear, task management).
    var lifecycle: LifecycleManager? {
        get { self[LifecycleKey.self] }
        set { self[LifecycleKey.self] = newValue }
    }

    /// Key event handler registration and dispatch.
    var keyEventDispatcher: KeyEventDispatcher? {
        get { self[KeyEventDispatcherKey.self] }
        set { self[KeyEventDispatcherKey.self] = newValue }
    }

    /// Cache for memoized subtree rendering results.
    var renderCache: RenderCache? {
        get { self[RenderCacheKey.self] }
        set { self[RenderCacheKey.self] = newValue }
    }

    /// Preference value collection during rendering.
    var preferenceStorage: PreferenceStorage? {
        get { self[PreferenceStorageKey.self] }
        set { self[PreferenceStorageKey.self] = newValue }
    }

    /// The current breathing animation phase (0-1) for the focus indicator.
    var pulsePhase: Double {
        get { self[PulsePhaseKey.self] }
        set { self[PulsePhaseKey.self] = newValue }
    }

    /// The cursor timer for TextField/SecureField animations.
    var cursorTimer: CursorTimer? {
        get { self[CursorTimerKey.self] }
        set { self[CursorTimerKey.self] = newValue }
    }

    /// The focus indicator color for the first border encountered in this subtree.
    var focusIndicatorColor: Color? {
        get { self[FocusIndicatorColorKey.self] }
        set { self[FocusIndicatorColorKey.self] = newValue }
    }

    /// The ID of the focus section that child views should register in.
    var activeFocusSectionID: String? {
        get { self[ActiveFocusSectionKey.self] }
        set { self[ActiveFocusSectionKey.self] = newValue }
    }
}
