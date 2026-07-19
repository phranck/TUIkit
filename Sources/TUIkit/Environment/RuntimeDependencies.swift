//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RuntimeDependencies.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Runtime Clock

/// Injectable wall clock used by time-based rendering services.
struct RuntimeClock: Sendable {
    /// System wall clock used by production runtimes.
    static let system = Self {
        Date().timeIntervalSinceReferenceDate
    }

    /// Provider returning seconds since the Foundation reference date.
    private let nowProvider: @Sendable () -> TimeInterval

    /// Creates a clock backed by the supplied provider.
    init(now: @escaping @Sendable () -> TimeInterval) {
        self.nowProvider = now
    }

    /// Returns the current wall-clock value.
    func now() -> TimeInterval {
        nowProvider()
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
