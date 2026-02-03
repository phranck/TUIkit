//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PulseTimer.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

import Foundation

/// Drives the breathing animation for the active focus section indicator.
///
/// `PulseTimer` maintains a phase value (0–1) that oscillates smoothly
/// using a sine curve. On each step, it calls `setNeedsRender()` to
/// trigger a re-render with the updated phase.
///
/// The timer runs on its own `DispatchSourceTimer`, completely independent
/// from the Spinner animation (which uses Swift Concurrency tasks) and
/// the RenderLoop (which renders on demand via `AppState.needsRender`).
///
/// ## Breathing Cycle
///
/// - The phase follows `sin(step * π / totalSteps)`, producing a smooth
///   0 → 1 → 0 oscillation.
/// - Default: 10 steps at 300ms each = 3 second cycle.
/// - At phase 0: color is dimmed (20% of accent). At phase 1: full accent.
///
/// ## Usage
///
/// ```swift
/// let pulse = PulseTimer(renderNotifier: appState)
/// pulse.start()
/// // ... later
/// pulse.stop()
/// ```
final class PulseTimer {
    /// The number of discrete steps in a half-cycle (dim → bright).
    ///
    /// A full breathing cycle (dim → bright → dim) is `totalHalfSteps * 2` steps.
    /// At 150ms per step and 10 half-steps: full cycle = 20 × 150ms = 3 seconds.
    private let totalHalfSteps = 10

    /// The interval between steps in milliseconds.
    private let stepIntervalMs = 150

    /// The current step in the full cycle (0 ..< totalHalfSteps * 2).
    private var currentStep = 0

    /// The GCD timer source.
    private var timer: DispatchSourceTimer?

    /// The render notifier to trigger re-renders.
    private weak var renderNotifier: AppState?

    /// The current pulse phase (0–1), computed from the current step.
    ///
    /// Uses a sine curve mapped to 0–1 for smooth breathing:
    /// - Step 0: phase = 0 (dimmest)
    /// - Step totalHalfSteps: phase = 1 (brightest)
    /// - Step totalHalfSteps * 2: phase = 0 (dimmest, cycle repeats)
    var phase: Double {
        let fullCycle = totalHalfSteps * 2
        let normalized = Double(currentStep) / Double(fullCycle)
        // sin(0) = 0, sin(π) = 0, peak at sin(π/2) = 1
        return sin(normalized * .pi)
    }

    /// Creates a new pulse timer.
    ///
    /// - Parameter renderNotifier: The app state to notify when a re-render
    ///   is needed. Held weakly to avoid retain cycles.
    init(renderNotifier: AppState) {
        self.renderNotifier = renderNotifier
    }

    deinit {
        stop()
    }
}

// MARK: - Internal API

extension PulseTimer {
    /// Starts the breathing animation.
    ///
    /// If the timer is already running, this is a no-op.
    func start() {
        guard timer == nil else { return }

        let source = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        let interval = DispatchTimeInterval.milliseconds(stepIntervalMs)
        source.schedule(deadline: .now() + interval, repeating: interval)

        source.setEventHandler { [weak self] in
            guard let self else { return }
            self.currentStep = (self.currentStep + 1) % (self.totalHalfSteps * 2)
            self.renderNotifier?.setNeedsRender()
        }

        source.resume()
        timer = source
    }

    /// Stops the breathing animation.
    func stop() {
        timer?.cancel()
        timer = nil
        currentStep = 0
    }
}
