//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TraceRecorder.swift
//
//  License: MIT

import Foundation

/// Thread-safe event storage for deterministic runtime characterizations.
package final class TraceRecorder<Event: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [Event] = []

    package init() {}

    package func record(_ event: Event) {
        lock.lock()
        defer { lock.unlock() }
        events.append(event)
    }

    package func snapshot() -> [Event] {
        lock.lock()
        defer { lock.unlock() }
        return events
    }

    package func reset() {
        lock.lock()
        defer { lock.unlock() }
        events.removeAll(keepingCapacity: true)
    }
}
