//  🖥️ TUIKit — Terminal UI Kit for Swift
//  CursorTimer.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

/// Drives the cursor animation for TextField and SecureField.
///
/// `CursorTimer` derives two phase values for different animation styles:
/// - `blinkVisible`: Boolean for sharp on/off blinking
/// - `pulsePhase`: Smooth 0-1 sine wave for pulsing
///
/// The application event loop owns animation deadlines, so this type never
/// creates a background timer or invalidates an idle application.
///
/// ## Animation Speeds
///
/// The speed is controlled by ``TextCursorStyle/Speed``:
/// - `.slow`: 1000ms cycle (visible 500ms, hidden 500ms)
/// - `.regular`: 660ms cycle (visible 330ms, hidden 330ms)
/// - `.fast`: 400ms cycle (visible 200ms, hidden 200ms)
///
/// ## Usage
///
/// ```swift
/// let cursor = CursorTimer(clock: runtimeClock)
/// cursor.start()
/// // In render code:
/// if cursor.blinkVisible(for: .regular) {
///     // show cursor
/// }
/// let phase = cursor.pulsePhase(for: .regular)
/// ```
@MainActor
final class CursorTimer {
    /// Monotonic runtime clock used for phase calculation.
    private let clock: RuntimeClock

    /// Monotonic timestamp at which the current cursor cycle began.
    private var startTime: TimeInterval?

    /// Creates a new cursor timer.
    ///
    /// - Parameter clock: Monotonic runtime clock used for animation phases.
    init(clock: RuntimeClock) {
        self.clock = clock
    }
}

// MARK: - Phase Computation

extension CursorTimer {
    /// Returns whether the cursor should be visible for blink animation.
    ///
    /// - Parameter speed: The cursor speed setting.
    /// - Returns: `true` if cursor should be visible, `false` if hidden.
    func blinkVisible(for speed: TextCursorStyle.Speed) -> Bool {
        let cycleMs = speed.blinkCycleMs
        let elapsedMs = elapsedMilliseconds
        let positionInCycle = elapsedMs % cycleMs
        // Visible for first half of cycle
        return positionInCycle < (cycleMs / 2)
    }

    /// Returns the pulse phase (0-1) for smooth cursor animation.
    ///
    /// The phase follows a sine curve for smooth breathing:
    /// - 0.0: Dimmest
    /// - 1.0: Brightest
    ///
    /// - Parameter speed: The cursor speed setting.
    /// - Returns: Phase value between 0 and 1.
    func pulsePhase(for speed: TextCursorStyle.Speed) -> Double {
        let cycleMs = speed.pulseCycleMs
        let elapsedMs = elapsedMilliseconds
        let positionInCycle = elapsedMs % cycleMs
        let normalized = Double(positionInCycle) / Double(cycleMs)
        // Sine wave: 0 → 1 → 0 over the cycle
        return sin(normalized * .pi)
    }
}

// MARK: - Phase Control

extension CursorTimer {
    /// Starts the cursor animation phase clock.
    ///
    /// If the phase clock is already active, this is a no-op.
    func start() {
        guard startTime == nil else { return }
        startTime = clock.now()
    }

    /// Stops the cursor animation phase clock.
    func stop() {
        startTime = nil
    }

    /// Resets the cursor animation to the visible/bright state.
    ///
    /// Call this when a text field gains focus to ensure the cursor
    /// starts in a visible state.
    func reset() {
        startTime = clock.now()
    }
}

// MARK: - Private Helpers

private extension CursorTimer {
    /// Elapsed whole milliseconds in the current cursor cycle.
    var elapsedMilliseconds: Int {
        guard let startTime else { return 0 }
        return Int(max(0, clock.now() - startTime) * 1_000)
    }
}

// MARK: - Speed Cycle Durations

extension TextCursorStyle.Speed {
    /// The blink cycle duration in milliseconds (on + off).
    var blinkCycleMs: Int {
        switch self {
        case .slow: 1000     // 500ms on, 500ms off
        case .regular: 660   // 330ms on, 330ms off
        case .fast: 400      // 200ms on, 200ms off
        }
    }

    /// The pulse cycle duration in milliseconds (dim → bright → dim).
    var pulseCycleMs: Int {
        switch self {
        case .slow: 1200     // 1.2 second breathing cycle
        case .regular: 800   // 0.8 second breathing cycle
        case .fast: 500      // 0.5 second breathing cycle
        }
    }
}
