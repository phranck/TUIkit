//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LifecycleModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - OnAppear Modifier

/// A modifier that executes an action when a view first appears.
struct OnAppearModifier<Content: View>: View {
    /// The content view.
    let content: Content

    /// Unique token to track this view's lifecycle.
    let token: String

    /// The action to execute on first appearance.
    let action: () -> Void

    var body: Never {
        fatalError("OnAppearModifier renders via Renderable")
    }
}

extension OnAppearModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Record appearance and execute action if first time
        _ = context.environment.lifecycle!.recordAppear(token: token, action: action)

        // Render content
        return TUIkit.renderToBuffer(content, context: context)
    }
}

// MARK: - OnDisappear Modifier

/// A modifier that executes an action when a view disappears.
struct OnDisappearModifier<Content: View>: View {
    /// The content view.
    let content: Content

    /// Unique token to track this view's lifecycle.
    let token: String

    /// The action to execute when the view disappears.
    let action: () -> Void

    var body: Never {
        fatalError("OnDisappearModifier renders via Renderable")
    }
}

extension OnDisappearModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Register the disappear callback
        context.environment.lifecycle!.registerDisappear(token: token, action: action)

        // Mark as visible in current render
        _ = context.environment.lifecycle!.recordAppear(token: token, action: {})

        // Render content
        return TUIkit.renderToBuffer(content, context: context)
    }
}

// MARK: - Task Modifier

/// A modifier that starts an async task when a view appears.
///
/// The task is cancelled when the view disappears.
struct TaskModifier<Content: View>: View {
    /// The content view.
    let content: Content

    /// Unique token to track this view's lifecycle.
    let token: String

    /// The async task to execute.
    let task: @Sendable () async -> Void

    /// Task priority.
    let priority: TaskPriority

    var body: Never {
        fatalError("TaskModifier renders via Renderable")
    }
}

extension TaskModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let lifecycle = context.environment.lifecycle!

        // Start task on first appearance
        let isFirstAppear = !lifecycle.hasAppeared(token: token)

        _ = lifecycle.recordAppear(token: token) {
            // Only start task on first appear
        }

        if isFirstAppear {
            lifecycle.startTask(token: token, priority: priority, operation: task)
        }

        // Register disappear callback to cancel task
        lifecycle.registerDisappear(token: token) { [lifecycle] in
            lifecycle.cancelTask(token: token)
        }

        // Render content
        return TUIkit.renderToBuffer(content, context: context)
    }
}
