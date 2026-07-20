//  🖥️ TUIkit — Terminal UI Kit for Swift
//  RuntimeAnimationSchedulerTests.swift
//
//  License: MIT

import Testing
import TUIkitTestSupport

@testable import TUIkit

@MainActor
@Suite("Runtime Animation Scheduler Tests")
struct RuntimeAnimationSchedulerTests {
    @Test("Injected clock controls the next animation deadline", .timeLimit(.minutes(1)))
    func injectedClockControlsDeadline() async {
        let deadlines = TraceRecorder<Double>()
        let sleepStarted = AsyncSignal()
        let releaseSleep = AsyncSignal()
        let channel = RuntimeEventChannel()
        let clock = RuntimeClock(
            now: { 10 },
            sleepUntil: { deadline in
                deadlines.record(deadline)
                sleepStarted.signal()
                await releaseSleep.wait()
                try Task.checkCancellation()
            }
        )
        let scheduler = RuntimeAnimationScheduler(
            clock: clock,
            eventChannel: channel
        )
        defer {
            scheduler.stop()
            channel.finish()
        }

        scheduler.schedule(after: 0.05)
        await sleepStarted.wait()
        #expect(deadlines.snapshot() == [10.05])

        releaseSleep.signal()
        var iterator = channel.events.makeAsyncIterator()
        let event = await iterator.next()
        if case .animationDeadline = event {
            // Expected event.
        } else {
            Issue.record("Expected an animation deadline event")
        }
    }
}
