//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PulseTimerTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("PulseTimer Tests")
struct PulseTimerTests {

    @Test("Initial phase is zero")
    func initialPhaseZero() {
        let timer = PulseTimer(clock: RuntimeClock { 0 })
        #expect(timer.phase == 0)
    }

    @Test("Phase stays within 0-1 range")
    func phaseRange() {
        let timer = PulseTimer(clock: RuntimeClock { 0 })

        // Phase is computed from sin(), which for our mapping gives 0–1
        let phase = timer.phase
        #expect(phase >= 0 && phase <= 1)
    }

    @Test("Start and stop are balanced")
    func startStopBalanced() {
        let timer = PulseTimer(clock: RuntimeClock { 0 })

        // Should not crash when stopped without starting
        timer.stop()

        // Start then stop
        timer.start()
        timer.stop()

        // Double start should be a no-op
        timer.start()
        timer.start()
        timer.stop()
    }

    @Test("Phase follows the injected monotonic clock")
    func phaseFollowsClock() {
        let timeSource = ManualTimeSource()
        let timer = PulseTimer(clock: RuntimeClock { timeSource.now() })

        timer.start()
        timeSource.advance(by: 1)
        #expect(abs(timer.phase - 1) < 0.000_001)

        timeSource.advance(by: 1)
        #expect(abs(timer.phase) < 0.000_001)
    }
}
