//
//  TUIContext.swift
//  TUIKit
//
//  Central dependency container replacing scattered singletons.
//  Owned by AppRunner and threaded through RenderContext.
//

import Foundation

// MARK: - Lifecycle Manager

/// Manages view lifecycle tracking, disappear callbacks, and async tasks.
///
/// Bundles the previously separate `LifecycleTracker`, `DisappearCallbackStorage`,
/// and `TaskStorage` singletons into a single cohesive manager.
/// All mutable state is protected by `NSLock`.
public final class LifecycleManager: @unchecked Sendable {

    /// Lock protecting all mutable state.
    private let lock = NSLock()

    // MARK: - Lifecycle Tracking

    /// Set of tokens that have appeared.
    private var appearedTokens: Set<String> = []

    /// Set of tokens that are currently visible (for onDisappear tracking).
    private var visibleTokens: Set<String> = []

    /// Tokens seen during the current render pass.
    private var currentRenderTokens: Set<String> = []

    // MARK: - Disappear Callbacks

    /// Callbacks registered for view disappearance.
    private var disappearCallbacks: [String: () -> Void] = [:]

    // MARK: - Task Storage

    /// Running async tasks keyed by lifecycle token.
    private var tasks: [String: Task<Void, Never>] = [:]

    // MARK: - Init

    /// Creates a new lifecycle manager.
    public init() {}

    // MARK: - Render Pass Tracking

    /// Marks the start of a new render pass.
    internal func beginRenderPass() {
        lock.lock()
        defer { lock.unlock() }
        currentRenderTokens.removeAll()
    }

    /// Marks the end of a render pass and triggers onDisappear for views that are no longer visible.
    internal func endRenderPass() {
        lock.lock()
        let disappeared = visibleTokens.subtracting(currentRenderTokens)
        for token in disappeared {
            appearedTokens.remove(token)
        }
        visibleTokens = currentRenderTokens
        let callbacks = disappearCallbacks
        lock.unlock()

        // Execute callbacks outside the lock to avoid deadlocks
        for token in disappeared {
            callbacks[token]?()
        }
    }

    // MARK: - Appear Tracking

    /// Records that a view with the given token appeared.
    ///
    /// - Parameters:
    ///   - token: Unique identifier for the view.
    ///   - action: The onAppear action to execute.
    /// - Returns: True if this is the first appearance (action was executed).
    @discardableResult
    internal func recordAppear(token: String, action: () -> Void) -> Bool {
        lock.lock()
        currentRenderTokens.insert(token)

        if !appearedTokens.contains(token) {
            appearedTokens.insert(token)
            lock.unlock()
            action()
            return true
        }
        lock.unlock()
        return false
    }

    /// Checks if a view has appeared before.
    internal func hasAppeared(token: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return appearedTokens.contains(token)
    }

    // MARK: - Disappear Callbacks

    /// Registers a callback for when a view with the given token disappears.
    ///
    /// - Parameters:
    ///   - token: Unique identifier for the view.
    ///   - action: The onDisappear action to execute.
    internal func registerDisappear(token: String, action: @escaping () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        disappearCallbacks[token] = action
    }

    /// Unregisters the disappear callback for the given token.
    internal func unregisterDisappear(token: String) {
        lock.lock()
        defer { lock.unlock() }
        disappearCallbacks.removeValue(forKey: token)
    }

    // MARK: - Task Management

    /// Starts an async task associated with a lifecycle token.
    ///
    /// If a task already exists for the token, it is cancelled first.
    ///
    /// - Parameters:
    ///   - token: Unique identifier for the view.
    ///   - priority: The task priority.
    ///   - operation: The async operation to execute.
    internal func startTask(
        token: String,
        priority: TaskPriority,
        operation: @escaping @Sendable () async -> Void
    ) {
        lock.lock()
        tasks[token]?.cancel()
        tasks[token] = Task(priority: priority) {
            await operation()
        }
        lock.unlock()
    }

    /// Cancels and removes the task associated with the given token.
    internal func cancelTask(token: String) {
        lock.lock()
        tasks[token]?.cancel()
        tasks.removeValue(forKey: token)
        lock.unlock()
    }

    // MARK: - Reset

    /// Resets all lifecycle state.
    ///
    /// Cancels all running tasks, clears all callbacks and tracking state.
    internal func reset() {
        lock.lock()
        appearedTokens.removeAll()
        visibleTokens.removeAll()
        currentRenderTokens.removeAll()
        disappearCallbacks.removeAll()
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
        lock.unlock()
    }
}

// MARK: - TUI Context

/// Central dependency container for TUIKit runtime services.
///
/// `TUIContext` replaces the scattered singleton pattern by bundling all
/// framework-internal services into a single object owned by `AppRunner`.
/// It is threaded through `RenderContext` so that view modifiers can access
/// services without relying on global state.
///
/// ## Services
///
/// - ``lifecycle``: View lifecycle tracking (appear/disappear/task)
/// - ``keyEventDispatcher``: Key event handler registration and dispatch
/// - ``preferences``: Preference value collection during rendering
///
/// ## Usage
///
/// View modifiers access the context through `RenderContext`:
///
/// ```swift
/// extension MyModifier: Renderable {
///     func renderToBuffer(context: RenderContext) -> FrameBuffer {
///         context.tuiContext.keyEventDispatcher.addHandler { event in
///             // handle key
///         }
///         return TUIKit.renderToBuffer(content, context: context)
///     }
/// }
/// ```
public final class TUIContext: @unchecked Sendable {

    /// View lifecycle tracking (appear, disappear, task management).
    public let lifecycle: LifecycleManager

    /// Key event handler registration and dispatch.
    public let keyEventDispatcher: KeyEventDispatcher

    /// Preference value collection during rendering.
    public let preferences: PreferenceStorage

    /// Creates a new TUI context with fresh instances of all services.
    public init() {
        self.lifecycle = LifecycleManager()
        self.keyEventDispatcher = KeyEventDispatcher()
        self.preferences = PreferenceStorage()
    }

    /// Creates a new TUI context with the given services.
    ///
    /// Useful for testing where you want to inject mock services.
    ///
    /// - Parameters:
    ///   - lifecycle: The lifecycle manager to use.
    ///   - keyEventDispatcher: The key event dispatcher to use.
    ///   - preferences: The preference storage to use.
    public init(
        lifecycle: LifecycleManager,
        keyEventDispatcher: KeyEventDispatcher,
        preferences: PreferenceStorage
    ) {
        self.lifecycle = lifecycle
        self.keyEventDispatcher = keyEventDispatcher
        self.preferences = preferences
    }

    /// Resets all services to their initial state.
    internal func reset() {
        lifecycle.reset()
        keyEventDispatcher.clearHandlers()
        preferences.reset()
    }
}
