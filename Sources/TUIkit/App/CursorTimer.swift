//  TUIKit - Terminal UI Kit for Swift
//  CursorTimer.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

/// Drives the cursor animation for TextField and SecureField.
///
/// `CursorTimer` maintains two phase values for different animation styles:
/// - `blinkVisible`: Boolean for sharp on/off blinking
/// - `pulsePhase`: Smooth 0-1 sine wave for pulsing
///
/// The timer runs independently from the ``PulseTimer`` (which handles focus indicators)
/// to allow different animation speeds and precise control over cursor timing.
///
/// ## Animation Speeds
///
/// The speed is controlled by ``TextCursorStyle/Speed``:
/// - `.slow`: 800ms cycle (visible 400ms, hidden 400ms)
/// - `.regular`: 530ms cycle (visible 265ms, hidden 265ms)
/// - `.fast`: 300ms cycle (visible 150ms, hidden 150ms)
///
/// ## Usage
///
/// ```swift
/// let cursor = CursorTimer(renderNotifier: appState)
/// cursor.start()
/// // In render code:
/// if cursor.blinkVisible(for: .regular) {
///     // show cursor
/// }
/// let phase = cursor.pulsePhase(for: .regular)
/// ```
final class CursorTimer {
    /// Base tick interval in milliseconds.
    /// We use a fast tick (50ms) and derive phases from elapsed time.
    private let tickIntervalMs = 50

    /// Elapsed ticks since timer started.
    private var elapsedTicks = 0

    /// The GCD timer source.
    private var timer: DispatchSourceTimer?

    /// The render notifier to trigger re-renders.
    private weak var renderNotifier: AppState?

    /// Creates a new cursor timer.
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

// MARK: - Phase Computation

extension CursorTimer {
    /// Returns whether the cursor should be visible for blink animation.
    ///
    /// - Parameter speed: The cursor speed setting.
    /// - Returns: `true` if cursor should be visible, `false` if hidden.
    func blinkVisible(for speed: TextCursorStyle.Speed) -> Bool {
        let cycleMs = speed.blinkCycleMs
        let elapsedMs = elapsedTicks * tickIntervalMs
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
        let elapsedMs = elapsedTicks * tickIntervalMs
        let positionInCycle = elapsedMs % cycleMs
        let normalized = Double(positionInCycle) / Double(cycleMs)
        // Sine wave: 0 → 1 → 0 over the cycle
        return sin(normalized * .pi)
    }
}

// MARK: - Timer Control

extension CursorTimer {
    /// Starts the cursor animation timer.
    ///
    /// If the timer is already running, this is a no-op.
    func start() {
        guard timer == nil else { return }

        let source = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        let interval = DispatchTimeInterval.milliseconds(tickIntervalMs)
        source.schedule(deadline: .now() + interval, repeating: interval)

        source.setEventHandler { [weak self] in
            guard let self else { return }
            self.elapsedTicks += 1
            self.renderNotifier?.setNeedsRender()
        }

        source.resume()
        timer = source
    }

    /// Stops the cursor animation timer.
    func stop() {
        timer?.cancel()
        timer = nil
        elapsedTicks = 0
    }

    /// Resets the cursor animation to the visible/bright state.
    ///
    /// Call this when a text field gains focus to ensure the cursor
    /// starts in a visible state.
    func reset() {
        elapsedTicks = 0
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
