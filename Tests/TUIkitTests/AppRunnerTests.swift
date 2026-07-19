//  🖥️ TUIkit — Terminal UI Kit for Swift
//  AppRunnerTests.swift
//
//  License: MIT

import Testing
import TUIkitTestSupport

@testable import TUIkit

@MainActor
@Suite("AppRunner Tests", .serialized)
struct AppRunnerTests {
    @Test("App runner yields the MainActor to view tasks before shutdown")
    func yieldsMainActorToViewTasks() async throws {
        let events = TraceRecorder<String>()
        let eventChannel = RuntimeEventChannel()
        let terminal = MockTerminal()
        let context = TUIContext()
        let runner = AppRunner(
            app: MainActorTaskApp(events: events, eventChannel: eventChannel),
            terminal: terminal,
            tuiContext: context,
            eventChannel: eventChannel,
            inputSource: nil,
            signals: nil
        )

        try await runner.run()

        #expect(events.snapshot() == ["completed"])
    }

    @Test("Idle app does not request periodic renders", .timeLimit(.minutes(1)))
    func idleAppDoesNotRequestPeriodicRenders() async throws {
        let invalidations = TraceRecorder<String>()
        let taskStarted = AsyncSignal()
        let releaseTask = AsyncSignal()
        let eventChannel = RuntimeEventChannel()
        let context = TUIContext()
        context.appState.observe {
            invalidations.record("render")
        }
        let runner = AppRunner(
            app: IdleTaskApp(
                taskStarted: taskStarted,
                releaseTask: releaseTask,
                eventChannel: eventChannel
            ),
            terminal: MockTerminal(),
            tuiContext: context,
            eventChannel: eventChannel,
            inputSource: nil,
            signals: nil
        )

        let runTask = Task {
            try await runner.run()
        }
        await taskStarted.wait()
        try await ContinuousClock().sleep(for: .milliseconds(250))
        releaseTask.signal()
        try await runTask.value

        #expect(invalidations.snapshot().isEmpty)
    }

    @Test("Terminal failures are thrown after terminal cleanup")
    func terminalFailureIsThrownAfterCleanup() async {
        let expectedFailure = TerminalIOFailure(
            operation: .write,
            errorCode: 5,
            remainingByteCount: 4
        )
        let terminal = MockTerminal()
        terminal.pendingIOFailure = expectedFailure
        let eventChannel = RuntimeEventChannel()
        let runner = AppRunner(
            app: MainActorTaskApp(events: TraceRecorder<String>(), eventChannel: eventChannel),
            terminal: terminal,
            tuiContext: TUIContext(),
            eventChannel: eventChannel,
            inputSource: nil,
            signals: nil
        )

        do {
            try await runner.run()
            Issue.record("Expected the terminal failure to be thrown")
        } catch let failure as TerminalIOFailure {
            #expect(failure == expectedFailure)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(!terminal.isRawModeEnabled)
        #expect(!terminal.isCursorHidden)
        #expect(!terminal.isInAlternateScreen)
    }
}

@MainActor
private struct MainActorTaskApp: App {
    let events: TraceRecorder<String>
    let eventChannel: RuntimeEventChannel

    init() {
        self.events = TraceRecorder<String>()
        self.eventChannel = RuntimeEventChannel()
    }

    init(events: TraceRecorder<String>, eventChannel: RuntimeEventChannel) {
        self.events = events
        self.eventChannel = eventChannel
    }

    var body: some Scene {
        WindowGroup {
            Text("Task")
                .task {
                    await MainActor.run {
                        events.record("completed")
                        eventChannel.send(.shutdownRequested)
                    }
                }
        }
    }
}

@MainActor
private struct IdleTaskApp: App {
    let taskStarted: AsyncSignal
    let releaseTask: AsyncSignal
    let eventChannel: RuntimeEventChannel

    init() {
        self.taskStarted = AsyncSignal()
        self.releaseTask = AsyncSignal()
        self.eventChannel = RuntimeEventChannel()
    }

    init(
        taskStarted: AsyncSignal,
        releaseTask: AsyncSignal,
        eventChannel: RuntimeEventChannel
    ) {
        self.taskStarted = taskStarted
        self.releaseTask = releaseTask
        self.eventChannel = eventChannel
    }

    var body: some Scene {
        WindowGroup {
            Text("Idle")
                .task {
                    taskStarted.signal()
                    await releaseTask.wait()
                    eventChannel.send(.shutdownRequested)
                }
        }
    }
}
