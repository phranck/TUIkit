//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Lock.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

#if canImport(os) && os(macOS)
import os
#endif

/// A cross-platform lock wrapper that uses the best available implementation.
///
/// On macOS, uses `OSAllocatedUnfairLock` for optimal performance
/// (unfair lock with no syscall in the uncontended case). On Linux and other
/// non-macOS platforms, falls back to `NSLock`.
///
/// This type is `@unchecked Sendable` because the underlying lock implementations
/// are thread-safe by design.
public final class Lock<State: Sendable>: @unchecked Sendable {
    #if canImport(os) && os(macOS)
    private let _lock: OSAllocatedUnfairLock<State>

    /// Creates a lock with the given initial state.
    ///
    /// - Parameter initialState: The initial protected state.
    public init(initialState: State) {
        _lock = OSAllocatedUnfairLock(initialState: initialState)
    }

    /// Executes the closure while holding the lock and returns the result.
    ///
    /// - Parameter body: The closure to execute with exclusive access to the state.
    /// - Returns: The value returned by the closure.
    public func withLock<R: Sendable>(_ body: @Sendable (inout State) throws -> R) rethrows -> R {
        try _lock.withLock(body)
    }
    #else
    private let _lock = NSLock()
    private var _state: State

    /// Creates a lock with the given initial state.
    ///
    /// - Parameter initialState: The initial protected state.
    public init(initialState: State) {
        _state = initialState
    }

    /// Executes the closure while holding the lock and returns the result.
    ///
    /// - Parameter body: The closure to execute with exclusive access to the state.
    /// - Returns: The value returned by the closure.
    public func withLock<R>(_ body: (inout State) throws -> R) rethrows -> R {
        _lock.lock()
        defer { _lock.unlock() }
        return try body(&_state)
    }
    #endif
}
