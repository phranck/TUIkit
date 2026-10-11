//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RecordingURLTransport.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import TUIkitImage

/// Scripted transport recording every call and returning enqueued responses.
///
/// Tests drive the transport by calling ``enqueue(data:response:)`` before a
/// coordinator load; the calls are surfaced through ``calls``. ``pause(atCallIndex:)``
/// suspends a specific call so tests can observe intermediate state
/// (dedup, cancellation) before resolving it.
actor RecordingURLTransport: URLImageDataTransport {

    /// A recorded transport invocation.
    struct Call: Sendable {
        let request: URLRequest
    }

    /// Every call the transport received, in order.
    private(set) var calls: [Call] = []

    /// FIFO of scripted responses.
    private var responses: [(Data, URLResponse)] = []

    /// Call indices whose fetch waits on a continuation.
    private var pausedIndices: Set<Int> = []

    /// Continuations for currently paused fetches.
    private var pausedContinuations: [CheckedContinuation<Void, Never>] = []

    /// Enqueues a scripted response returned by the next fetch.
    func enqueue(data: Data, response: URLResponse) {
        responses.append((data, response))
    }

    /// Suspends the fetch at the given zero-based call index until
    /// ``resumePaused()`` runs.
    func pause(atCallIndex index: Int) {
        pausedIndices.insert(index)
    }

    /// Resumes every currently paused fetch.
    func resumePaused() {
        let continuations = pausedContinuations
        pausedContinuations.removeAll()
        for continuation in continuations {
            continuation.resume()
        }
    }

    /// Number of paused fetches cancelled since the last observation.
    private var cancelledFetchCount = 0

    // MARK: - URLImageDataTransport

    func fetch(request: URLRequest) async throws -> (Data, URLResponse) {
        let callIndex = calls.count
        calls.append(Call(request: request))

        if pausedIndices.contains(callIndex) {
            try await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    pausedContinuations.append(continuation)
                }
                try Task.checkCancellation()
            } onCancel: {
                Task { await self.recordCancelledFetch() }
            }
        }

        try Task.checkCancellation()

        guard !responses.isEmpty else {
            throw URLError(.badServerResponse)
        }
        return responses.removeFirst()
    }

    /// Waits up to `timeout` seconds for a paused fetch to observe cancellation.
    ///
    /// Poll rather than block so a missing cancellation surfaces as `false`
    /// instead of a hung test.
    func awaitCancelledFetch(timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if cancelledFetchCount > 0 {
                cancelledFetchCount -= 1
                return true
            }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        return false
    }

    /// Records that a paused fetch was cancelled while waiting.
    private func recordCancelledFetch() {
        cancelledFetchCount += 1
    }
}
