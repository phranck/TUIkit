//
//  LifecycleModifier.swift
//  SwiftTUI
//
//  Lifecycle modifiers: .onAppear(), .onDisappear(), .task()
//

import Foundation

// MARK: - Lifecycle Tracker

/// Tracks which views have appeared to prevent duplicate onAppear calls.
///
/// Since views are recreated on each render, we use a token-based system
/// to track which views have already triggered their onAppear action.
public final class LifecycleTracker: @unchecked Sendable {
    /// Shared instance for the running application.
    public static let shared = LifecycleTracker()

    /// Set of tokens that have appeared.
    private var appearedTokens: Set<String> = []

    /// Set of tokens that are currently visible (for onDisappear tracking).
    private var visibleTokens: Set<String> = []

    /// Tokens seen during the current render pass.
    private var currentRenderTokens: Set<String> = []

    private init() {}

    /// Marks the start of a new render pass.
    internal func beginRenderPass() {
        currentRenderTokens.removeAll()
    }

    /// Marks the end of a render pass and triggers onDisappear for views that are no longer visible.
    internal func endRenderPass(onDisappear: [String: () -> Void]) {
        // Find tokens that were visible but are no longer rendered
        let disappearedTokens = visibleTokens.subtracting(currentRenderTokens)

        for token in disappearedTokens {
            onDisappear[token]?()
            appearedTokens.remove(token)
        }

        // Update visible tokens for next pass
        visibleTokens = currentRenderTokens
    }

    /// Records that a view with the given token appeared.
    ///
    /// - Parameters:
    ///   - token: Unique identifier for the view.
    ///   - action: The onAppear action to execute.
    /// - Returns: True if this is the first appearance (action should run).
    internal func recordAppear(token: String, action: () -> Void) -> Bool {
        currentRenderTokens.insert(token)

        if !appearedTokens.contains(token) {
            appearedTokens.insert(token)
            action()
            return true
        }
        return false
    }

    /// Checks if a view has appeared before.
    internal func hasAppeared(token: String) -> Bool {
        appearedTokens.contains(token)
    }

    /// Resets all tracking state.
    internal func reset() {
        appearedTokens.removeAll()
        visibleTokens.removeAll()
        currentRenderTokens.removeAll()
    }
}

// MARK: - OnAppear Modifier

/// A modifier that executes an action when a view first appears.
public struct OnAppearModifier<Content: TView>: TView {
    /// The content view.
    let content: Content

    /// Unique token to track this view's lifecycle.
    let token: String

    /// The action to execute on first appearance.
    let action: () -> Void

    public var body: Never {
        fatalError("OnAppearModifier renders via Renderable")
    }
}

extension OnAppearModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Record appearance and execute action if first time
        _ = LifecycleTracker.shared.recordAppear(token: token, action: action)

        // Render content
        return SwiftTUI.renderToBuffer(content, context: context)
    }
}

// MARK: - OnDisappear Modifier

/// Storage for onDisappear callbacks.
public final class DisappearCallbackStorage: @unchecked Sendable {
    public static let shared = DisappearCallbackStorage()

    private var callbacks: [String: () -> Void] = [:]

    private init() {}

    internal func register(token: String, action: @escaping () -> Void) {
        callbacks[token] = action
    }

    internal func unregister(token: String) {
        callbacks.removeValue(forKey: token)
    }

    internal var allCallbacks: [String: () -> Void] {
        callbacks
    }

    internal func reset() {
        callbacks.removeAll()
    }
}

/// A modifier that executes an action when a view disappears.
public struct OnDisappearModifier<Content: TView>: TView {
    /// The content view.
    let content: Content

    /// Unique token to track this view's lifecycle.
    let token: String

    /// The action to execute when the view disappears.
    let action: () -> Void

    public var body: Never {
        fatalError("OnDisappearModifier renders via Renderable")
    }
}

extension OnDisappearModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Register the disappear callback
        DisappearCallbackStorage.shared.register(token: token, action: action)

        // Mark as visible in current render
        _ = LifecycleTracker.shared.recordAppear(token: token, action: {})

        // Render content
        return SwiftTUI.renderToBuffer(content, context: context)
    }
}

// MARK: - Task Modifier

/// A modifier that starts an async task when a view appears.
///
/// The task is cancelled when the view disappears.
public struct TaskModifier<Content: TView>: TView {
    /// The content view.
    let content: Content

    /// Unique token to track this view's lifecycle.
    let token: String

    /// The async task to execute.
    let task: @Sendable () async -> Void

    /// Task priority.
    let priority: TaskPriority

    public var body: Never {
        fatalError("TaskModifier renders via Renderable")
    }
}

/// Storage for running tasks.
public final class TaskStorage: @unchecked Sendable {
    public static let shared = TaskStorage()

    private var tasks: [String: Task<Void, Never>] = [:]

    private init() {}

    internal func startTask(token: String, priority: TaskPriority, operation: @escaping @Sendable () async -> Void) {
        // Cancel existing task if any
        tasks[token]?.cancel()

        // Start new task
        tasks[token] = Task(priority: priority) {
            await operation()
        }
    }

    internal func cancelTask(token: String) {
        tasks[token]?.cancel()
        tasks.removeValue(forKey: token)
    }

    internal func reset() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
    }
}

extension TaskModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Start task on first appearance
        let isFirstAppear = !LifecycleTracker.shared.hasAppeared(token: token)

        _ = LifecycleTracker.shared.recordAppear(token: token) {
            // Only start task on first appear
        }

        if isFirstAppear {
            TaskStorage.shared.startTask(token: token, priority: priority, operation: task)
        }

        // Register disappear callback to cancel task
        DisappearCallbackStorage.shared.register(token: token) {
            TaskStorage.shared.cancelTask(token: token)
        }

        // Render content
        return SwiftTUI.renderToBuffer(content, context: context)
    }
}

// MARK: - Token Generator

/// Generates unique tokens for lifecycle tracking.
private final class TokenGenerator: @unchecked Sendable {
    static let shared = TokenGenerator()

    private var counter: UInt64 = 0
    private let lock = NSLock()

    func next() -> String {
        lock.lock()
        defer { lock.unlock() }
        counter += 1
        return "lifecycle-\(counter)"
    }
}

// MARK: - TView Extension

extension TView {
    /// Executes an action when this view first appears.
    ///
    /// The action is only executed once per view appearance. If the view
    /// is removed and then added again, the action will execute again.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct ContentView: TView {
    ///     var body: some TView {
    ///         Text("Hello")
    ///             .onAppear {
    ///                 loadData()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter action: The action to execute.
    /// - Returns: A view that executes the action on appearance.
    public func onAppear(perform action: @escaping () -> Void) -> some TView {
        OnAppearModifier(
            content: self,
            token: TokenGenerator.shared.next(),
            action: action
        )
    }

    /// Executes an action when this view disappears.
    ///
    /// The action is executed when the view is no longer rendered.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct ContentView: TView {
    ///     var body: some TView {
    ///         Text("Hello")
    ///             .onDisappear {
    ///                 cleanup()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter action: The action to execute.
    /// - Returns: A view that executes the action on disappearance.
    public func onDisappear(perform action: @escaping () -> Void) -> some TView {
        OnDisappearModifier(
            content: self,
            token: TokenGenerator.shared.next(),
            action: action
        )
    }

    /// Starts an async task when this view appears.
    ///
    /// The task is automatically cancelled when the view disappears.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct ContentView: TView {
    ///     var body: some TView {
    ///         Text("Loading...")
    ///             .task {
    ///                 await fetchData()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - priority: The task priority (default: .userInitiated).
    ///   - action: The async action to execute.
    /// - Returns: A view that starts the task on appearance.
    public func task(
        priority: TaskPriority = .userInitiated,
        _ action: @escaping @Sendable () async -> Void
    ) -> some TView {
        TaskModifier(
            content: self,
            token: TokenGenerator.shared.next(),
            task: action,
            priority: priority
        )
    }
}
