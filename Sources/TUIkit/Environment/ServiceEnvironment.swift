//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ServiceEnvironment.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Localization Service

/// EnvironmentKey for the localization service.
private struct LocalizationServiceKey: EnvironmentKey {
    static var defaultValue: LocalizationService { LocalizationService.transient() }
}

// MARK: - Runtime Clock

/// EnvironmentKey for time-based runtime services.
private struct RuntimeClockKey: EnvironmentKey {
    static let defaultValue = RuntimeClock.system
}

// MARK: - Application Storage

/// EnvironmentKey for the runtime-owned AppStorage backend.
private struct StorageBackendKey: EnvironmentKey {
    static var defaultValue: any StorageBackend { VolatileStorageBackend() }
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

// MARK: - Preference Storage

/// EnvironmentKey for preference value collection during rendering.
private struct PreferenceStorageKey: EnvironmentKey {
    static let defaultValue: PreferenceStorage? = nil
}

// MARK: - Runtime Diagnostics

/// EnvironmentKey for diagnostics emitted during view traversal.
private struct RuntimeDiagnosticsKey: EnvironmentKey {
    static let defaultValue: RuntimeDiagnostics? = nil
}

// MARK: - Pulse Phase

/// EnvironmentKey for the focus indicator breathing animation phase.
private struct PulsePhaseKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

// MARK: - Cursor Timer

/// EnvironmentKey for TextField/SecureField cursor blink animation.
private struct CursorTimerKey: EnvironmentKey {
    static let defaultValue: CursorTimer? = nil
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

    /// The localization service for retrieving translated strings.
    public var localizationService: LocalizationService {
        get { self[LocalizationServiceKey.self] }
        set { self[LocalizationServiceKey.self] = newValue }
    }

    /// The currently active language.
    public var currentLanguage: LocalizationService.Language {
        localizationService.currentLanguage
    }

    /// Clock used by time-based views and services in this runtime.
    var runtimeClock: RuntimeClock {
        get { self[RuntimeClockKey.self] }
        set { self[RuntimeClockKey.self] = newValue }
    }

    /// Persistent storage backend owned by this runtime.
    var storageBackend: any StorageBackend {
        get { self[StorageBackendKey.self] }
        set { self[StorageBackendKey.self] = newValue }
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

    /// Preference value collection during rendering.
    var preferenceStorage: PreferenceStorage? {
        get { self[PreferenceStorageKey.self] }
        set { self[PreferenceStorageKey.self] = newValue }
    }

    /// Diagnostics emitted by the runtime that owns this render tree.
    var runtimeDiagnostics: RuntimeDiagnostics? {
        get { self[RuntimeDiagnosticsKey.self] }
        set { self[RuntimeDiagnosticsKey.self] = newValue }
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
