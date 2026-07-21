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
        if context.phase == .render {
            _ = context.environment.lifecycle!.recordAppear(
                identity: scopedContext.identity,
                action: action
            )
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
        if context.phase == .render {
            let lifecycle = context.environment.lifecycle!
            lifecycle.registerDisappear(identity: scopedContext.identity, action: action)
            _ = lifecycle.recordAppear(identity: scopedContext.identity, action: {})
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
        if context.phase == .render {
            context.environment.lifecycle!.updateTask(
                identity: scopedContext.identity,
                id: MountedTaskID.value,
                priority: priority,
                operation: task
            )
        }

        return TUIkit.renderToBuffer(content, context: scopedContext)
    }
}

// MARK: - Task Identity

private enum MountedTaskID: Hashable {
    case value
}
