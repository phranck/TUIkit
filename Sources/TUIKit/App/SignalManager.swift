//
//  SignalManager.swift
//  TUIKit
//
//  Manages POSIX signal handlers for terminal resize and graceful shutdown.
//

import Foundation

#if canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Darwin)
    import Darwin
#endif

// MARK: - Signal Flags

/// Flag set by the SIGWINCH signal handler to request a re-render.
///
/// Marked `nonisolated(unsafe)` because it is written from a signal handler
/// and read from the main loop. A single-word Bool write/read is practically
/// atomic on arm64/x86_64. Using `Atomic<Bool>` from the `Synchronization`
/// module would be cleaner but requires macOS 15+.
nonisolated(unsafe) private var signalNeedsRerender = false

/// Flag set by the SIGINT signal handler to request a graceful shutdown.
///
/// The actual cleanup (disabling raw mode, restoring cursor, exiting
/// alternate screen) happens in the main loop — signal handlers must
/// not call non-async-signal-safe functions like `write()` or `fflush()`.
nonisolated(unsafe) private var signalNeedsShutdown = false

// MARK: - Signal Manager

/// Manages POSIX signal handlers for the application lifecycle.
///
/// Encapsulates the global signal flags and handler installation.
/// The flags remain file-private globals because C signal handlers
/// cannot capture Swift object references.
///
/// ## Usage
///
/// ```swift
/// let signals = SignalManager()
/// signals.install()
///
/// while running {
///     if signals.shouldShutdown { break }
///     if signals.consumeRerenderFlag() { render() }
/// }
/// ```
internal struct SignalManager {
    /// Whether a graceful shutdown was requested (SIGINT).
    var shouldShutdown: Bool {
        signalNeedsShutdown
    }

    /// Checks and resets the rerender flag (SIGWINCH).
    ///
    /// Returns `true` if a re-render was requested since the last call,
    /// then resets the flag. This consume-on-read pattern prevents
    /// redundant renders.
    ///
    /// - Returns: `true` if a terminal resize triggered a rerender request.
    mutating func consumeRerenderFlag() -> Bool {
        guard signalNeedsRerender else { return false }
        signalNeedsRerender = false
        return true
    }

    /// Requests a re-render programmatically.
    ///
    /// Called by the `AppState` observer to signal that application
    /// state has changed and the UI needs updating.
    func requestRerender() {
        signalNeedsRerender = true
    }

    /// Installs POSIX signal handlers for SIGINT and SIGWINCH.
    ///
    /// - SIGINT (Ctrl+C): Sets the shutdown flag for graceful cleanup.
    /// - SIGWINCH (terminal resize): Sets the rerender flag.
    ///
    /// Signal handlers only set boolean flags — all actual work
    /// happens in the main loop, which is async-signal-safe.
    func install() {
        signal(SIGINT) { _ in
            signalNeedsShutdown = true
        }
        signal(SIGWINCH) { _ in
            signalNeedsRerender = true
        }
    }
}
