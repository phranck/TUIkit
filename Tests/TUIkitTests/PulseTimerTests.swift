//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PulseTimerTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@Suite("PulseTimer Tests")
struct PulseTimerTests {

    @Test("Initial phase is zero")
    func initialPhaseZero() {
        let appState = AppState()
        let timer = PulseTimer(renderNotifier: appState)
        #expect(timer.phase == 0)
    }

    @Test("Phase stays within 0-1 range")
    func phaseRange() {
        let appState = AppState()
        let timer = PulseTimer(renderNotifier: appState)

        // Phase is computed from sin(), which for our mapping gives 0–1
        let phase = timer.phase
        #expect(phase >= 0 && phase <= 1)
    }

    @Test("Start and stop are balanced")
    func startStopBalanced() {
        let appState = AppState()
        let timer = PulseTimer(renderNotifier: appState)

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
}
