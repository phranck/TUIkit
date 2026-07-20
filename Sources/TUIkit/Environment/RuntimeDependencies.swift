//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RuntimeDependencies.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Runtime Clock

/// Injectable monotonic clock used by time-based rendering services.
struct RuntimeClock: Sendable {
    /// Continuous system clock used by production runtimes.
    static let system: Self = {
        let clock = ContinuousClock()
        let origin = clock.now

        return Self(
            now: {
                origin.duration(to: clock.now).timeInterval
            },
            sleepUntil: { deadline in
                try await clock.sleep(
                    until: origin.advanced(by: .seconds(deadline))
                )
            }
        )
    }()

    /// Provider returning seconds since the Foundation reference date.
    private let nowProvider: @Sendable () -> TimeInterval

    /// Provider suspending until the supplied monotonic timestamp.
    private let sleepUntilProvider: @Sendable (TimeInterval) async throws -> Void

    /// Creates a clock backed by the supplied provider.
    init(now: @escaping @Sendable () -> TimeInterval) {
        self.nowProvider = now
        let clock = ContinuousClock()
        self.sleepUntilProvider = { deadline in
            let remaining = max(0, deadline - now())
            try await clock.sleep(for: .seconds(remaining))
        }
    }

    /// Creates a fully injectable clock for deterministic deadline tests.
    init(
        now: @escaping @Sendable () -> TimeInterval,
        sleepUntil: @escaping @Sendable (TimeInterval) async throws -> Void
    ) {
        self.nowProvider = now
        self.sleepUntilProvider = sleepUntil
    }

    /// Returns the current wall-clock value.
    func now() -> TimeInterval {
        nowProvider()
    }

    /// Suspends until the supplied monotonic timestamp.
    func sleep(until deadline: TimeInterval) async throws {
        try await sleepUntilProvider(deadline)
    }
}

// MARK: - Duration Conversion

private extension Duration {
    /// Exact duration represented as fractional seconds.
    var timeInterval: TimeInterval {
        let components = self.components
        return TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }
}

// MARK: - Volatile Storage

/// Process-local storage used by isolated and test runtimes.
final class VolatileStorageBackend: StorageBackend, @unchecked Sendable {
    /// Encoded values keyed by their application storage key.
    private var values: [String: Data] = [:]

    /// Lock protecting encoded values.
    private let lock = NSLock()

    /// Creates an empty volatile backend.
    init() {}

    func value<T: Codable>(forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        guard let data = values[key] else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func setValue<T: Codable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        lock.lock()
        values[key] = data
        lock.unlock()
    }

    func removeValue(forKey key: String) {
        lock.lock()
        values.removeValue(forKey: key)
        lock.unlock()
    }

    func synchronize() {}
}
