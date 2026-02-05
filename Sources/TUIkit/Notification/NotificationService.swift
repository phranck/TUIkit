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
/// and consumed by the ``NotificationHostModifier`` during rendering.
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
    init(message: String, duration: TimeInterval) {
        self.id = UUID()
        self.message = message
        self.duration = duration
        self.postedAt = Date().timeIntervalSinceReferenceDate
    }
}

// MARK: - Notification Service

/// Central service for posting and managing notifications.
///
/// `NotificationService` lives in the environment and accepts fire-and-forget
/// notification posts from anywhere in the view hierarchy. The
/// ``NotificationHostModifier`` reads the active entries and renders them
/// as a stacked overlay.
///
/// ## Usage
///
/// Post notifications from anywhere using the shared instance:
///
/// ```swift
/// NotificationService.current.post("Saved!")
/// NotificationService.current.post("Connection lost", duration: 5.0)
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
    /// The shared instance used by the running application.
    ///
    /// This is a static accessor rather than environment-only because TUIKit
    /// does not have an `@Environment` property wrapper. Button callbacks,
    /// `onSelect` handlers, and other user-facing closures run outside the
    /// render context and therefore cannot read `EnvironmentValues`. A static
    /// reference is the only way to reach the service from those call sites.
    ///
    /// The same pattern is used by ``RenderNotifier/current`` for the same
    /// reason. For tests, create a fresh instance instead of using `current`.
    ///
    /// ```swift
    /// NotificationService.current.post("Done!")
    /// ```
    nonisolated(unsafe) public static var current = NotificationService()

    /// Lock for thread-safe access to the entries array.
    private let lock = NSLock()

    /// The active notification entries, ordered by posting time.
    private var entries: [NotificationEntry] = []

    /// Creates an empty notification service.
    public init() {}
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
        let entry = NotificationEntry(message: message, duration: duration)
        lock.lock()
        entries.append(entry)
        lock.unlock()
        RenderNotifier.current.setNeedsRender()
    }

    /// Returns a snapshot of all currently active notifications.
    ///
    /// Entries whose total animation time (fade-in + visible + fade-out) has
    /// elapsed are pruned before the snapshot is returned.
    func activeEntries() -> [NotificationEntry] {
        let now = Date().timeIntervalSinceReferenceDate
        let totalAnimationOverhead = NotificationTiming.fadeInDuration + NotificationTiming.fadeOutDuration

        lock.lock()
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
}

// MARK: - Environment Key

/// Environment key for the notification service.
private struct NotificationServiceKey: EnvironmentKey {
    static let defaultValue = NotificationService()
}

extension EnvironmentValues {
    /// The notification service for posting and managing notifications.
    ///
    /// Used internally by the ``NotificationHostModifier`` to read active entries.
    /// Post notifications via the static accessor:
    ///
    /// ```swift
    /// NotificationService.current.post("Saved!")
    /// ```
    public var notificationService: NotificationService {
        get { self[NotificationServiceKey.self] }
        set { self[NotificationServiceKey.self] = newValue }
    }
}
