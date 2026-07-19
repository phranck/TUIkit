//  🖥️ TUIkit — Terminal UI Kit for Swift
//  RuntimeEventSource.swift
//
//  License: MIT

import Dispatch

#if canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Darwin)
    import Darwin
#endif

// MARK: - Runtime Event

/// Work serialized by the owning application runtime.
internal enum RuntimeEvent: Sendable {
    /// Application state requested another render pass.
    case renderRequested

    /// Standard input has bytes ready to consume.
    case inputAvailable

    /// The terminal dimensions changed.
    case terminalResized

    /// The active animation reached its next frame deadline.
    case animationDeadline

    /// The application should shut down gracefully.
    case shutdownRequested
}

// MARK: - Runtime Event Channel

/// Thread-safe bridge from system callbacks to the async application loop.
internal final class RuntimeEventChannel: Sendable {
    /// Events consumed by exactly one application runtime.
    let events: AsyncStream<RuntimeEvent>

    /// Thread-safe continuation used by signal, input, and state callbacks.
    private let continuation: AsyncStream<RuntimeEvent>.Continuation

    /// Creates an unbounded channel so shutdown and resize events are never dropped.
    init() {
        let pair = AsyncStream.makeStream(
            of: RuntimeEvent.self,
            bufferingPolicy: .unbounded
        )
        self.events = pair.stream
        self.continuation = pair.continuation
    }

    /// Enqueues work for the application runtime.
    func send(_ event: RuntimeEvent) {
        continuation.yield(event)
    }

    /// Creates a nonisolated callback suitable for Dispatch event handlers.
    func sender(for event: RuntimeEvent) -> @Sendable () -> Void {
        { [self] in
            send(event)
        }
    }

    /// Finishes the event stream and resumes a suspended consumer.
    func finish() {
        continuation.finish()
    }
}

// MARK: - Terminal Input Source

/// Converts terminal file-descriptor readiness into runtime events.
@MainActor
internal final class TerminalInputSource {
    /// Standard input descriptor observed by the source.
    private let fileDescriptor: Int32

    /// Active dispatch source, if input observation has started.
    private var source: DispatchSourceRead?

    /// Creates an input source for the supplied descriptor.
    init(fileDescriptor: Int32 = STDIN_FILENO) {
        self.fileDescriptor = fileDescriptor
    }
}

// MARK: - Internal API

extension TerminalInputSource {
    /// Starts observing input readiness.
    func start(sendingTo channel: RuntimeEventChannel) {
        guard source == nil else { return }

        let source = DispatchSource.makeReadSource(
            fileDescriptor: fileDescriptor,
            queue: DispatchQueue.global(qos: .userInteractive)
        )
        source.setEventHandler(handler: channel.sender(for: .inputAvailable))
        source.resume()
        self.source = source
    }

    /// Stops observing without closing the terminal-owned descriptor.
    func stop() {
        source?.cancel()
        source = nil
    }
}
