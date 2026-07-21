//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PendingFrameEffects.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - Pending Frame Effects

/// Per-pass records for effects that **outlive** the frame.
///
/// This is the pending-diff half of the effect classification rule (see
/// ``RenderPhase``):
///
/// > Does the effect outlive the frame? **Yes → pending diff (this type).**
/// > No → pass collector (`RenderPassCollectors`).
///
/// Lifetime effects — `onAppear`/`onDisappear` actions, `.task` mounts,
/// `onChange`/`onPreferenceChange` actions, and GC liveness — must derive
/// from the frame's **committed** tree, exactly once. A traversal therefore
/// never applies them directly; it records them here, and the frame commit
/// replays only the FINAL pass's records against the live runtime.
/// Records of discarded passes (measurement, superseded main pass) are
/// dropped with their instance — nothing to roll back, because nothing live
/// was touched.
///
/// ## Two record kinds
///
/// - **Deferred effects** (``recordEffect(_:)``): an ordered command log of
///   closures replayed in traversal order by ``commitDeferredEffects()``
///   after the frame is written to the terminal. Effect sites capture their
///   own manager calls (e.g. `lifecycle.recordAppear`), so this type needs
///   no knowledge of the managers involved and the managers keep their
///   existing diff semantics (appear-once, task restart IDs, disappear on
///   removal).
/// - **Liveness sets** (``markActive(_:)``, ``markSubtreeActive(_:)``):
///   the identities the final tree keeps alive. The frame commit hands them
///   to the state/cache/observation GC, so records that only a discarded
///   pass touched are collected at the end of the frame.
///
/// ## Live path
///
/// Rendering outside `RenderLoop` (e.g. `ViewRenderer`, test harnesses)
/// runs without a `PendingFrameEffects` instance in the environment; effect
/// sites fall back to their immediate live semantics there. See
/// ``TUIkitCore/EnvironmentValues/pendingFrameEffects``.
@MainActor
package final class PendingFrameEffects {
    /// Identities the current pass keeps alive for identity-based GC.
    package private(set) var activeIdentities: Set<ViewIdentity> = []

    /// Roots of cached subtrees whose descendants stay alive without being
    /// traversed (see `EquatableView` cache hits).
    package private(set) var activeSubtreeRoots: Set<ViewIdentity> = []

    /// Ordered command log of lifetime effects, replayed at frame commit.
    private var deferredEffects: [() -> Void] = []

    /// Creates an empty record set for one render pass.
    package init() {}

    /// Number of recorded deferred effects, for tests and diagnostics.
    package var deferredEffectCount: Int {
        deferredEffects.count
    }

    /// Marks an identity as alive in the final tree.
    ///
    /// - Parameter identity: The structural identity to keep.
    package func markActive(_ identity: ViewIdentity) {
        activeIdentities.insert(identity)
    }

    /// Marks a cached subtree root whose descendants stay alive without
    /// traversal.
    ///
    /// - Parameter root: The subtree root identity.
    package func markSubtreeActive(_ root: ViewIdentity) {
        activeSubtreeRoots.insert(root)
    }

    /// Appends a lifetime effect to the command log.
    ///
    /// The closure runs at frame commit (after terminal output), in
    /// traversal order, exactly once — and only if this pass becomes the
    /// frame's final pass.
    ///
    /// - Parameter effect: The deferred manager call.
    package func recordEffect(_ effect: @escaping () -> Void) {
        deferredEffects.append(effect)
    }

    /// Replays the recorded lifetime effects in traversal order.
    ///
    /// Called exactly once per frame by the commit step, after the frame
    /// buffer has been written to the terminal.
    package func commitDeferredEffects() {
        let effects = deferredEffects
        deferredEffects.removeAll()
        for effect in effects {
            effect()
        }
    }
}

// MARK: - Environment Key

/// EnvironmentKey for the current pass's pending effect records.
private struct PendingFrameEffectsKey: EnvironmentKey {
    static let defaultValue: PendingFrameEffects? = nil
}

extension EnvironmentValues {
    /// The pending effect records of the current render pass.
    ///
    /// `nil` outside `RenderLoop` frames (standalone `ViewRenderer`, test
    /// harnesses) — effect sites then apply their live semantics directly.
    package var pendingFrameEffects: PendingFrameEffects? {
        get { self[PendingFrameEffectsKey.self] }
        set { self[PendingFrameEffectsKey.self] = newValue }
    }
}
