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

    /// The action to execute on first appearance.
    let action: () -> Void

    var body: Never {
        fatalError("OnAppearModifier renders via Renderable")
    }
}

extension OnAppearModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let scopedContext = context.withIdentityScope("lifecycle.appear")
        // Lifetime effect (outlives the frame): recorded for the frame
        // commit; the live path (no pending records) applies it directly.
        if context.phase == .render {
            let lifecycle = context.environment.lifecycle!
            let identity = scopedContext.identity
            if let pendingEffects = context.environment.pendingFrameEffects {
                pendingEffects.recordEffect { [action] in
                    _ = lifecycle.recordAppear(identity: identity, action: action)
                }
            } else {
                _ = lifecycle.recordAppear(identity: identity, action: action)
            }
        }

        return TUIkit.renderToBuffer(content, context: scopedContext)
    }
}

// MARK: - OnDisappear Modifier

/// A modifier that executes an action when a view disappears.
struct OnDisappearModifier<Content: View>: View {
    /// The content view.
    let content: Content

    /// The action to execute when the view disappears.
    let action: () -> Void

    var body: Never {
        fatalError("OnDisappearModifier renders via Renderable")
    }
}

extension OnDisappearModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let scopedContext = context.withIdentityScope("lifecycle.disappear")
        // Lifetime effect (outlives the frame): recorded for the frame
        // commit; the live path (no pending records) applies it directly.
        if context.phase == .render {
            let lifecycle = context.environment.lifecycle!
            let identity = scopedContext.identity
            if let pendingEffects = context.environment.pendingFrameEffects {
                pendingEffects.recordEffect { [action] in
                    lifecycle.registerDisappear(identity: identity, action: action)
                    _ = lifecycle.recordAppear(identity: identity, action: {})
                }
            } else {
                lifecycle.registerDisappear(identity: identity, action: action)
                _ = lifecycle.recordAppear(identity: identity, action: {})
            }
        }

        return TUIkit.renderToBuffer(content, context: scopedContext)
    }
}

// MARK: - Task Modifier

/// A modifier that starts an async task when a view appears.
///
/// The task is cancelled when the view disappears.
struct TaskModifier<Content: View>: View {
    /// The content view.
    let content: Content

    /// The async task to execute.
    let task: @isolated(any) @Sendable () async -> Void

    /// Task priority.
    let priority: TaskPriority

    var body: Never {
        fatalError("TaskModifier renders via Renderable")
    }
}

extension TaskModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let scopedContext = context.withIdentityScope("lifecycle.task")
        // Lifetime effect (outlives the frame): recorded for the frame
        // commit; the live path (no pending records) applies it directly.
        // A task from a discarded pass is therefore never even started.
        if context.phase == .render {
            let lifecycle = context.environment.lifecycle!
            let identity = scopedContext.identity
            if let pendingEffects = context.environment.pendingFrameEffects {
                pendingEffects.recordEffect { [task, priority] in
                    lifecycle.updateTask(
                        identity: identity,
                        id: MountedTaskID.value,
                        priority: priority,
                        operation: task
                    )
                }
            } else {
                lifecycle.updateTask(
                    identity: identity,
                    id: MountedTaskID.value,
                    priority: priority,
                    operation: task
                )
            }
        }

        return TUIkit.renderToBuffer(content, context: scopedContext)
    }
}

// MARK: - Task Identity

private enum MountedTaskID: Hashable {
    case value
}
