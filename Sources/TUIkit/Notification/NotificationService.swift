//  🖥️ TUIKit — Terminal UI Kit for Swift
//  NotificationService.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Notification Entry

/// A single notification in the service queue.
///
/// Each entry carries the message, timing, and a unique identifier
/// for lifecycle tracking. Entries are created by ``NotificationService/post(_:duration:)``
/// and consumed by the `NotificationHostModifier` during rendering.
struct NotificationEntry: Identifiable, Sendable {
    /// Unique identifier for this notification.
    let id: UUID

    /// The notification message text.
    let message: String

    /// How long the notification stays visible (in seconds).
    let duration: TimeInterval

    /// Timestamp when this notification was posted.
    let postedAt: TimeInterval

    /// Creates a notification entry.
    ///
    /// - Parameters:
    ///   - message: The notification message text.
    ///   - duration: Display duration in seconds.
    init(message: String, duration: TimeInterval, postedAt: TimeInterval) {
        self.id = UUID()
        self.message = message
        self.duration = duration
        self.postedAt = postedAt
    }
}

// MARK: - Notification Service

/// Central service for posting and managing notifications.
///
/// `NotificationService` lives in the environment and accepts fire-and-forget
/// notification posts from anywhere in the view hierarchy. The
/// `NotificationHostModifier` reads the active entries and renders them
/// as a stacked overlay.
///
/// ## Usage
///
/// Read the service from the environment before posting:
///
/// ```swift
/// @Environment(\.notificationService) private var notifications
/// notifications.post("Saved!")
/// notifications.post("Connection lost", duration: 5.0)
/// ```
///
/// Attach the host once at the root of your view tree:
///
/// ```swift
/// ContentView()
///     .notificationHost()
/// ```
///
/// ## Lifecycle
///
/// Each notification goes through three phases:
/// 1. **Fade-in** (0.2s) — opacity ramps from 0 to 1
/// 2. **Visible** — stays at full opacity for `duration` seconds
/// 3. **Fade-out** (0.3s) — opacity ramps from 1 to 0, then entry is removed
///
/// The service automatically removes expired entries and triggers re-renders
/// for animation frames.
public final class NotificationService: @unchecked Sendable {
    /// Lock for thread-safe access to the entries array.
    private let lock = NSLock()

    /// The active notification entries, ordered by posting time.
    private var entries: [NotificationEntry] = []

    /// Clock used for posting and pruning entries.
    private var clock: RuntimeClock

    /// Runtime receiving invalidations after queue changes.
    private var invalidationSink: (any RenderInvalidationSink)?

    /// Creates an empty notification service.
    public init() {
        self.clock = .system
        self.invalidationSink = nil
    }

    /// Creates a notification service with runtime dependencies.
    init(
        clock: RuntimeClock,
        invalidationSink: (any RenderInvalidationSink)?
    ) {
        self.clock = clock
        self.invalidationSink = invalidationSink
    }
}

// MARK: - Public API

extension NotificationService {
    /// Posts a new notification.
    ///
    /// The notification appears immediately and auto-dismisses after `duration` seconds.
    ///
    /// - Parameters:
    ///   - message: The notification message text.
    ///   - duration: How long the notification stays visible in seconds (default: 3.0).
    public func post(_ message: String, duration: TimeInterval = 3.0) {
        lock.lock()
        let entry = NotificationEntry(
            message: message,
            duration: duration,
            postedAt: clock.now()
        )
        entries.append(entry)
        let invalidationSink = invalidationSink
        lock.unlock()
        invalidationSink?.invalidate(.renderOnly)
    }

    /// Returns a snapshot of all currently active notifications.
    ///
    /// Entries whose total animation time (fade-in + visible + fade-out) has
    /// elapsed are pruned before the snapshot is returned.
    func activeEntries() -> [NotificationEntry] {
        let totalAnimationOverhead = NotificationTiming.fadeInDuration + NotificationTiming.fadeOutDuration

        lock.lock()
        let now = clock.now()
        entries.removeAll { entry in
            let totalDuration = totalAnimationOverhead + entry.duration
            return (now - entry.postedAt) > totalDuration
        }
        let snapshot = entries
        lock.unlock()
        return snapshot
    }

    /// Removes all active notifications.
    func clear() {
        lock.lock()
        entries.removeAll()
        lock.unlock()
    }

    /// Associates this service with runtime dependencies.
    func setRuntimeDependencies(
        clock: RuntimeClock,
        invalidationSink: (any RenderInvalidationSink)?
    ) {
        lock.lock()
        self.clock = clock
        self.invalidationSink = invalidationSink
        lock.unlock()
    }
}

// MARK: - Environment Key

/// Environment key for the notification service.
private struct NotificationServiceKey: EnvironmentKey {
    static var defaultValue: NotificationService { NotificationService() }
}

extension EnvironmentValues {
    /// The notification service for posting and managing notifications.
    ///
    /// Used internally by the `NotificationHostModifier` to read active entries.
    /// Read this value with `@Environment` and retain it in callbacks:
    ///
    /// ```swift
    /// @Environment(\.notificationService) private var notifications
    /// ```
    public var notificationService: NotificationService {
        get { self[NotificationServiceKey.self] }
        set { self[NotificationServiceKey.self] = newValue }
    }
}
