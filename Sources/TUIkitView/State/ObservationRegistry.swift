//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ObservationRegistry.swift
//
//  Created by LAYERED.work
//  License: MIT

import Observation
import TUIkitCore

/// Tracks Observation registrations by committed structural identity.
///
/// Observation callbacks are one-shot and cannot be explicitly detached. Each
/// render therefore replaces the active generation for an identity. Callbacks
/// from older generations or unmounted identities become inert and retain no
/// runtime through their weak references.
package final class ObservationRegistry: Sendable {
    private struct RegistryState: Sendable {
        var nextGeneration: UInt64 = 0
        var generations: [ViewIdentity: UInt64] = [:]
        var activeIdentities: Set<ViewIdentity> = []
    }

    private let state = Lock(initialState: RegistryState())

    /// Creates an empty observation registry.
    package init() {}

    /// Number of live identity registrations for tests and diagnostics.
    package var count: Int {
        state.withLock { $0.generations.count }
    }

    /// Whether the registry currently retains no identity registrations.
    package var isEmpty: Bool {
        state.withLock { $0.generations.isEmpty }
    }
}

// MARK: - Render Pass Lifecycle

package extension ObservationRegistry {
    /// Starts liveness tracking for a render pass.
    func beginRenderPass() {
        state.withLock { registry in
            registry.activeIdentities.removeAll(keepingCapacity: true)
        }
    }

    /// Keeps an identity's registration alive through the end-of-frame GC.
    ///
    /// Liveness is decoupled from ``track(identity:invalidationSink:_:)``:
    /// inside a `RenderLoop` frame only the FINAL pass's identities are
    /// marked (via the pending-effects liveness sets), so a registration
    /// made by a discarded pass is collected by ``endRenderPass()`` and its
    /// callback turns inert.
    func markActive(_ identity: ViewIdentity) {
        state.withLock { registry in
            _ = registry.activeIdentities.insert(identity)
        }
    }

    /// Keeps existing registrations below a cached subtree mounted.
    func markSubtreeActive(_ root: ViewIdentity) {
        state.withLock { registry in
            let mountedIdentities = registry.generations.keys.filter { identity in
                identity == root || root.isAncestor(of: identity)
            }
            registry.activeIdentities.formUnion(mountedIdentities)
        }
    }

    /// Removes registrations for identities absent from the completed pass.
    func endRenderPass() {
        state.withLock { registry in
            registry.generations = registry.generations.filter {
                registry.activeIdentities.contains($0.key)
            }
        }
    }

    /// Removes every registration during runtime shutdown.
    func reset() {
        state.withLock { registry in
            registry.nextGeneration = 0
            registry.generations.removeAll()
            registry.activeIdentities.removeAll()
        }
    }
}

// MARK: - Tracking

package extension ObservationRegistry {
    /// Evaluates a view body while tracking its observable dependencies.
    ///
    /// A newer evaluation at the same identity supersedes the previous
    /// callback. Only the current generation may invalidate the owning
    /// runtime. Tracking does NOT mark the identity alive — callers route
    /// liveness through ``markActive(_:)`` (directly on the live path, via
    /// the pending-effects sets inside a `RenderLoop` frame).
    @MainActor
    func track<Result>(
        identity: ViewIdentity,
        invalidationSink: (any RenderInvalidationSink)?,
        _ body: () -> Result
    ) -> Result {
        let generation = state.withLock { registry -> UInt64 in
            registry.nextGeneration &+= 1
            let generation = registry.nextGeneration
            registry.generations[identity] = generation
            return generation
        }
        let weakSink = WeakInvalidationSink(invalidationSink)

        return withObservationTracking {
            body()
        } onChange: { [weak self, weakSink] in
            guard self?.isCurrent(generation, for: identity) == true else { return }
            weakSink.value?.invalidate(.subtree(identity))
        }
    }
}

// MARK: - Private Helpers

private extension ObservationRegistry {
    func isCurrent(_ generation: UInt64, for identity: ViewIdentity) -> Bool {
        state.withLock { registry in
            registry.generations[identity] == generation
        }
    }
}

private final class WeakInvalidationSink: @unchecked Sendable {
    weak var value: (any RenderInvalidationSink)?

    init(_ value: (any RenderInvalidationSink)?) {
        self.value = value
    }
}
