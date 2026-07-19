//  🖥️ TUIkit — Terminal UI Kit for Swift
//  ManualTimeSource.swift
//
//  License: MIT

import Foundation

/// Thread-safe mutable time source for deterministic phase tests.
final class ManualTimeSource: @unchecked Sendable {
    /// Lock protecting the current timestamp.
    private let lock = NSLock()

    /// Current monotonic timestamp in seconds.
    private var timestamp: TimeInterval

    /// Creates a source at the supplied timestamp.
    init(now: TimeInterval = 0) {
        self.timestamp = now
    }

    /// Returns the current timestamp.
    func now() -> TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return timestamp
    }

    /// Advances the timestamp by a deterministic duration.
    func advance(by interval: TimeInterval) {
        lock.lock()
        timestamp += interval
        lock.unlock()
    }
}
