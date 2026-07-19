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
    func yieldsMainActorToViewTasks() async {
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

        await runner.run()

        #expect(events.snapshot() == ["completed"])
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
