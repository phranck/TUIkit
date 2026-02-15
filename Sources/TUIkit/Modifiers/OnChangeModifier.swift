//  🖥️ TUIKit — Terminal UI Kit for Swift
//  OnChangeModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitView

// MARK: - OnChange Modifier

/// A modifier that observes a value and calls an action when it changes.
///
/// Created by the `.onChange(of:initial:_:)` view modifier. Stores the
/// previous value in ``StateStorage`` and compares on each render pass.
///
/// Multiple chained `.onChange(of:)` modifiers on the same view are
/// disambiguated via ``StateStorage/nextOnChangeIndex(for:)``.
struct OnChangeModifier<Content: View, V: Equatable>: View {
    /// The content view to wrap.
    let content: Content

    /// The value to observe for changes.
    let value: V

    /// Whether to fire the action on the first render pass.
    let initial: Bool

    /// The action to call with old and new values when a change is detected.
    let action: (V, V) -> Void

    var body: Never {
        fatalError("OnChangeModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension OnChangeModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let storage = context.environment.stateStorage!

        // Claim unique index for this onChange at this identity
        let index = storage.nextOnChangeIndex(for: context.identity)
        let key = StateStorage.StateKey(identity: context.identity, propertyIndex: index)

        // Compare with previous value
        if let oldValue: V = storage.trackedValue(for: key) {
            if oldValue != value {
                action(oldValue, value)
            }
        } else if initial {
            action(value, value)
        }

        // Store current value for next render pass
        storage.setTrackedValue(value, for: key)

        // Keep tracked values alive through GC
        storage.markActive(context.identity)

        return TUIkitView.renderToBuffer(content, context: context)
    }
}
