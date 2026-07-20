//  🖥️ TUIkit — Terminal UI Kit for Swift
//  RuntimeAnimationScheduler.swift
//
//  License: MIT

// MARK: - Runtime Animation Scheduler

/// Owns the single pending animation deadline for an application runtime.
@MainActor
internal final class RuntimeAnimationScheduler {
    /// Monotonic clock used to suspend until the next frame deadline.
    private let clock: RuntimeClock

    /// Runtime channel receiving completed animation deadlines.
    private let eventChannel: RuntimeEventChannel

    /// Currently pending deadline task, if animation is active.
    private var deadlineTask: Task<Void, Never>?

    /// Creates a scheduler owned by one application runtime.
    init(clock: RuntimeClock, eventChannel: RuntimeEventChannel) {
        self.clock = clock
        self.eventChannel = eventChannel
    }
}

// MARK: - Internal API

extension RuntimeAnimationScheduler {
    /// Replaces the pending deadline, or suspends animation when no interval is supplied.
    func schedule(after interval: Double?) {
        deadlineTask?.cancel()
        deadlineTask = nil

        guard let interval else { return }
        let deadline = clock.now() + interval
        deadlineTask = Task { [clock, eventChannel] in
            do {
                try await clock.sleep(until: deadline)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            eventChannel.send(.animationDeadline)
        }
    }

    /// Cancels the pending deadline during runtime shutdown.
    func stop() {
        deadlineTask?.cancel()
        deadlineTask = nil
    }
}
