//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PulseTimer.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

/// Drives the breathing animation for the active focus section indicator.
///
/// `PulseTimer` derives a phase value (0–1) from the runtime's monotonic
/// clock. The application event loop owns animation deadlines, so this type
/// never creates a background timer or invalidates an idle application.
///
/// ## Breathing Cycle
///
/// - The phase follows a sine curve, producing a smooth
///   0 → 1 → 0 oscillation.
/// - At phase 0: color is dimmed (20% of accent). At phase 1: full accent.
///
/// ## Usage
///
/// ```swift
/// let pulse = PulseTimer(clock: runtimeClock)
/// pulse.start()
/// // ... later
/// pulse.stop()
/// ```
@MainActor
final class PulseTimer {
    /// Duration of one dim → bright → dim cycle.
    private let cycleDuration: TimeInterval = 2

    /// Monotonic runtime clock used for phase calculation.
    private let clock: RuntimeClock

    /// Monotonic timestamp at which the current cycle began.
    private var startTime: TimeInterval?

    /// The current pulse phase (0–1), computed from the current step.
    ///
    /// Uses a sine curve mapped to 0–1 for smooth breathing:
    /// - Step 0: phase = 0 (dimmest)
    /// - Step totalHalfSteps: phase = 1 (brightest)
    /// - Step totalHalfSteps * 2: phase = 0 (dimmest, cycle repeats)
    var phase: Double {
        guard let startTime else { return 0 }
        let elapsed = max(0, clock.now() - startTime)
        let position = elapsed.truncatingRemainder(dividingBy: cycleDuration)
        let normalized = position / cycleDuration
        // sin(0) = 0, sin(π) = 0, peak at sin(π/2) = 1
        return sin(normalized * .pi)
    }

    /// Creates a new pulse timer.
    ///
    /// - Parameter clock: Monotonic runtime clock used for animation phases.
    init(clock: RuntimeClock) {
        self.clock = clock
    }
}

// MARK: - Internal API

extension PulseTimer {
    /// Starts the breathing animation.
    ///
    /// If the phase clock is already active, this is a no-op.
    func start() {
        guard startTime == nil else { return }
        startTime = clock.now()
    }

    /// Stops phase calculation for the breathing animation.
    func stop() {
        startTime = nil
    }

    /// Resets the animation to the brightest point (phase = 1).
    ///
    /// Called when focus changes to make the indicator immediately visible
    /// on the newly focused element instead of continuing mid-cycle.
    func reset() {
        startTime = clock.now() - cycleDuration / 2
    }
}
