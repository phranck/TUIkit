//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ObservationRegistryTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Observation
import Testing
import TUIkitCore

@testable import TUIkitView

@MainActor
@Suite("Observation Registry Tests")
struct ObservationRegistryTests {
    @Test("Repeated evaluation keeps one effective identity registration")
    func repeatedEvaluationDoesNotGrow() {
        let registry = ObservationRegistry()
        let sink = RecordingInvalidationSink()
        let model = ObservationModel()
        let identity = ViewIdentity(path: "Root/Observed")

        registry.beginRenderPass()
        registry.track(identity: identity, invalidationSink: sink) {
            _ = model.value
        }
        registry.endRenderPass()

        registry.beginRenderPass()
        registry.track(identity: identity, invalidationSink: sink) {
            _ = model.value
        }
        registry.endRenderPass()

        #expect(registry.count == 1)

        model.value = 1

        #expect(sink.invalidatedSubtrees == [identity])
    }

    @Test("Cached subtree keeps descendant registrations mounted")
    func cachedSubtreeKeepsDescendantsMounted() {
        let registry = ObservationRegistry()
        let sink = RecordingInvalidationSink()
        let model = ObservationModel()
        let root = ViewIdentity(path: "Root/Cached")
        let descendant = ViewIdentity(path: "Root/Cached/Observed")
        let sibling = ViewIdentity(path: "Root/Sibling")

        registry.beginRenderPass()
        registry.track(identity: descendant, invalidationSink: sink) {
            _ = model.value
        }
        registry.track(identity: sibling, invalidationSink: sink) {
            _ = model.value
        }
        registry.endRenderPass()

        registry.beginRenderPass()
        registry.markSubtreeActive(root)
        registry.endRenderPass()

        #expect(registry.count == 1)

        model.value = 1

        #expect(sink.invalidatedSubtrees == [descendant])
    }

    @Test("Unmount removes registration and makes pending callback inert")
    func unmountRemovesRegistration() {
        let registry = ObservationRegistry()
        let sink = RecordingInvalidationSink()
        let model = ObservationModel()
        let identity = ViewIdentity(path: "Root/Observed")

        registry.beginRenderPass()
        registry.track(identity: identity, invalidationSink: sink) {
            _ = model.value
        }
        registry.endRenderPass()

        registry.beginRenderPass()
        registry.endRenderPass()

        #expect(registry.isEmpty)

        model.value = 1

        #expect(sink.invalidatedSubtrees.isEmpty)
    }

    @Test("Reset releases every identity registration")
    func resetReleasesRegistrations() {
        let registry = ObservationRegistry()
        let sink = RecordingInvalidationSink()
        let model = ObservationModel()

        registry.beginRenderPass()
        for index in 0..<3 {
            registry.track(
                identity: ViewIdentity(path: "Root/\(index)"),
                invalidationSink: sink
            ) {
                _ = model.value
            }
        }
        registry.endRenderPass()

        #expect(registry.count == 3)

        registry.reset()

        #expect(registry.isEmpty)
    }
}

@Observable
private final class ObservationModel {
    var value = 0
}

private final class RecordingInvalidationSink: RenderInvalidationSink, @unchecked Sendable {
    private let lock = Lock(initialState: [ViewIdentity]())

    var invalidatedSubtrees: [ViewIdentity] {
        lock.withLock { $0 }
    }

    func invalidate(_ invalidation: RenderInvalidation) {
        guard case .subtree(let identity) = invalidation else { return }
        lock.withLock { identities in
            identities.append(identity)
        }
    }
}
