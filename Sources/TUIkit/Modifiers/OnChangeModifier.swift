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
        let pendingEffects = context.environment.pendingFrameEffects

        // Claim a unique index for this onChange at this identity. Inside a
        // RenderLoop pass the counter is pass-scoped, so main and correction
        // pass claim identical indices and tracked values stay stable.
        let index = pendingEffects?.nextOnChangeIndex(for: context.identity)
            ?? storage.nextOnChangeIndex(for: context.identity)
        let key = StateStorage.StateKey(identity: context.identity, propertyIndex: index)

        // Compare against the last COMMITTED frame's value. Writing the new
        // value back is a lifetime effect: it must happen exactly once at
        // frame commit, or a correction pass would see its own sibling
        // pass's value instead of the previous frame's.
        let oldValue: V? = storage.trackedValue(for: key)
        if let pendingEffects {
            pendingEffects.recordEffect { [value, initial, action] in
                fireIfChanged(oldValue: oldValue, newValue: value, initial: initial, action: action)
                storage.setTrackedValue(value, for: key)
            }
        } else {
            // Live path (ViewRenderer, harnesses): immediate semantics.
            fireIfChanged(oldValue: oldValue, newValue: value, initial: initial, action: action)
            storage.setTrackedValue(value, for: key)
        }

        // Keep tracked values alive through GC
        storage.markActive(context.identity)

        return TUIkitView.renderToBuffer(content, context: context)
    }
}

/// Runs an `onChange` action when the tracked value changed, or on the
/// first observation when `initial` is set.
private func fireIfChanged<V: Equatable>(
    oldValue: V?,
    newValue: V,
    initial: Bool,
    action: (V, V) -> Void
) {
    if let oldValue {
        if oldValue != newValue {
            action(oldValue, newValue)
        }
    } else if initial {
        action(newValue, newValue)
    }
}
