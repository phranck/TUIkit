//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AsyncSignal.swift
//
//  License: MIT

/// A buffered, one-shot signal for one deterministic async consumer.
package final class AsyncSignal: Sendable {
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    package init() {
        let pair = AsyncStream.makeStream(
            of: Void.self,
            bufferingPolicy: .bufferingOldest(1)
        )
        self.stream = pair.stream
        self.continuation = pair.continuation
    }

    package func signal() {
        continuation.yield()
        continuation.finish()
    }

    package func wait() async {
        var iterator = stream.makeAsyncIterator()
        _ = await iterator.next()
    }
}
