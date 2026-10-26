//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Preferences.swift
//
//  Created by LAYERED.work
//  License: MIT  Similar to SwiftUI's PreferenceKey system.
//

import TUIkitCore

// MARK: - Preference Modifier

/// A modifier that sets a preference value.
struct PreferenceModifier<Content: View, K: PreferenceKey>: View {
    /// The content view.
    let content: Content

    /// The preference value to set.
    let value: K.Value

    var body: Never {
        fatalError("PreferenceModifier renders via Renderable")
    }
}

extension PreferenceModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Set the preference value
        context.environment.preferenceStorage!.setValue(value, forKey: K.self)

        // Render content
        return TUIkit.renderToBuffer(content, context: context)
    }
}

// MARK: - OnPreferenceChange Modifier

/// A modifier that reacts to preference changes.
struct OnPreferenceChangeModifier<Content: View, K: PreferenceKey>: View
where K.Value: Equatable {
    /// The content view.
    let content: Content

    /// The action to perform when the preference changes.
    let action: (K.Value) -> Void

    var body: Never {
        fatalError("OnPreferenceChangeModifier renders via Renderable")
    }
}

extension OnPreferenceChangeModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let prefs = context.environment.preferenceStorage!
        let storage = context.environment.stateStorage!
        let pendingEffects = context.environment.pendingFrameEffects

        // Collect the subtree's preferences into a fresh scope.
        prefs.push()
        let buffer = TUIkit.renderToBuffer(content, context: context)
        let subtreeValues = prefs.pop()

        // SwiftUI semantics: the action fires when the subtree's reduced
        // value CHANGED against the last committed frame (and once on first
        // appearance). Firing and updating the tracked value are lifetime
        // effects — recorded for the frame commit so a discarded pass never
        // fires and never corrupts the tracked value. The tracking slot is
        // scoped per preference key type, so stacked onPreferenceChange
        // modifiers on one view do not collide.
        //
        // The effect captures the Sendable `PreferenceValues` and reads the
        // key inside `commitChange`: from Swift 6.2 on `K.Type` is not
        // Sendable (SE-0470), so a value read through `K.self` here could
        // not be captured by the deferred closure.
        let trackingIdentity = context.identity
            .scoped("preference.\(String(reflecting: K.self))")
        let key = StateStorage.StateKey(identity: trackingIdentity, propertyIndex: 0)
        let previousValue: K.Value? = storage.trackedValue(for: key)

        if let pendingEffects {
            pendingEffects.recordEffect { [action, previousValue, subtreeValues, storage, key, trackingIdentity] in
                Self.commitChange(
                    previousValue: previousValue,
                    subtreeValues: subtreeValues,
                    action: action,
                    storage: storage,
                    key: key,
                    trackingIdentity: trackingIdentity
                )
            }
        } else {
            // Live path (ViewRenderer, harnesses): immediate semantics.
            Self.commitChange(
                previousValue: previousValue,
                subtreeValues: subtreeValues,
                action: action,
                storage: storage,
                key: key,
                trackingIdentity: trackingIdentity
            )
        }

        return buffer
    }

    /// Fires the change action when the subtree value changed (or first
    /// appeared) and records the new value for the next frame's comparison.
    private static func commitChange(
        previousValue: K.Value?,
        subtreeValues: PreferenceValues,
        action: (K.Value) -> Void,
        storage: StateStorage,
        key: StateStorage.StateKey,
        trackingIdentity: ViewIdentity
    ) {
        let subtreeValue = subtreeValues[K.self]
        // `!=` on the optional also fires on first appearance (nil). It
        // stays a plain comparison because Swift 6.2 and newer reject the
        // autoclosure of `previousValue == nil || ...` for a value read
        // through `K.self` on the main actor.
        if previousValue != subtreeValue {
            action(subtreeValue)
        }
        storage.setTrackedValue(subtreeValue, for: key)
        storage.markActive(trackingIdentity)
    }
}

// MARK: - Common Preference Keys

/// A preference key for the navigation title.
public struct NavigationTitleKey: PreferenceKey {
    /// The default navigation title (empty string).
    public static let defaultValue: String = ""
}
