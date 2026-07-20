//  🖥️ TUIkit — Terminal UI Kit for Swift
//  CursorTimerTests.swift
//
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("CursorTimer Tests")
struct CursorTimerTests {
    @Test("Blink and pulse phases follow the injected monotonic clock")
    func phasesFollowClock() {
        let timeSource = ManualTimeSource()
        let timer = CursorTimer(clock: RuntimeClock { timeSource.now() })

        timer.start()
        #expect(timer.blinkVisible(for: .regular))

        timeSource.advance(by: 0.33)
        #expect(timer.blinkVisible(for: .regular) == false)

        timeSource.advance(by: 0.07)
        #expect(abs(timer.pulsePhase(for: .regular) - 1) < 0.000_001)

        timeSource.advance(by: 0.26)
        #expect(timer.blinkVisible(for: .regular))
    }
}
