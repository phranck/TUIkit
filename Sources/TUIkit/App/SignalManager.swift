//  🖥️ TUIKit — Terminal UI Kit for Swift
//  SignalManager.swift
//
//  Created by LAYERED.work
//  License: MIT

#if canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Darwin)
    import Darwin
#endif

import Dispatch

// MARK: - Signal Manager

/// Manages POSIX signal handlers for the application lifecycle.
///
/// Dispatch owns the low-level signal bridge, so no Swift state is read or
/// mutated from a POSIX signal handler. The application runtime receives
/// ordinary async events on its event channel.
@MainActor
internal final class SignalManager {
    /// C-compatible signal disposition returned by `signal()`.
    private typealias SignalDisposition = @convention(c) (Int32) -> Void

    /// One installed dispatch source and the disposition it replaced.
    private struct Registration {
        let number: Int32
        let previousDisposition: SignalDisposition?
        let source: DispatchSourceSignal
    }

    /// Active registrations owned by this application runtime.
    private var registrations: [Registration] = []

    /// Creates an uninstalled signal manager.
    init() {}
}

/// One-shot barrier for Dispatch source registration callbacks.
private final class SignalRegistrationBarrier: Sendable {
    /// Registration notifications consumed by the installer.
    let events: AsyncStream<Void>

    /// Thread-safe producer used by Dispatch callbacks.
    private let continuation: AsyncStream<Void>.Continuation

    /// Creates a barrier that preserves callbacks arriving before the wait.
    init() {
        let pair = AsyncStream.makeStream(
            of: Void.self,
            bufferingPolicy: .unbounded
        )
        self.events = pair.stream
        self.continuation = pair.continuation
    }

    /// Creates a nonisolated Dispatch callback.
    func callback() -> @Sendable () -> Void {
        { [self] in
            continuation.yield()
        }
    }

    /// Finishes the registration stream.
    func finish() {
        continuation.finish()
    }
}

// MARK: - Internal API

extension SignalManager {
    /// Installs dispatch-backed sources for resize and termination signals.
    func install(sendingTo channel: RuntimeEventChannel) async {
        guard registrations.isEmpty else { return }

        let barrier = SignalRegistrationBarrier()
        register(SIGWINCH, event: .terminalResized, sendingTo: channel, barrier: barrier)
        register(SIGINT, event: .shutdownRequested, sendingTo: channel, barrier: barrier)
        register(SIGTERM, event: .shutdownRequested, sendingTo: channel, barrier: barrier)

        var iterator = barrier.events.makeAsyncIterator()
        for _ in registrations {
            _ = await iterator.next()
        }
        barrier.finish()
    }

    /// Cancels all sources and restores the dispositions they replaced.
    func stop() {
        for registration in registrations {
            registration.source.cancel()
            #if !os(Linux)
                signal(registration.number, registration.previousDisposition)
            #endif
        }
        registrations.removeAll()
    }
}

// MARK: - Private Helpers

private extension SignalManager {
    /// Registers one platform dispatch source for a POSIX signal.
    func register(
        _ number: Int32,
        event: RuntimeEvent,
        sendingTo channel: RuntimeEventChannel,
        barrier: SignalRegistrationBarrier
    ) {
        #if os(Linux)
            // swift-corelibs Dispatch installs and owns the sigaction used by
            // its signalfd bridge. Replacing that disposition with SIG_IGN
            // prevents delivery on Linux.
            let previousDisposition: SignalDisposition? = nil
        #else
            // Darwin kqueue signal sources require the default disposition to
            // be suppressed so termination work stays in the async runtime.
            let previousDisposition = signal(number, SIG_IGN)
        #endif
        let source = DispatchSource.makeSignalSource(
            signal: number,
            queue: DispatchQueue.global(qos: .userInitiated)
        )
        source.setEventHandler(handler: channel.sender(for: event))
        source.setRegistrationHandler(handler: barrier.callback())
        source.resume()
        registrations.append(
            Registration(
                number: number,
                previousDisposition: previousDisposition,
                source: source
            )
        )
    }
}
