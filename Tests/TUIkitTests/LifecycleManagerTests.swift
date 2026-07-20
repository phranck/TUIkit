//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LifecycleManagerTests.swift
//
//  Created by LAYERED.work
//  License: MIT  render pass management, and async task lifecycle.
//

import Testing
import TUIkitTestSupport

@testable import TUIkit

// MARK: - Appear Tracking Tests

@MainActor
@Suite("LifecycleManager Appear Tests")
struct LifecycleManagerAppearTests {

    @Test("recordAppear returns true on first appearance")
    func firstAppearance() {
        let manager = LifecycleManager()
        nonisolated(unsafe) var actionCalled = false
        let result = manager.recordAppear(token: "view-1") {
            actionCalled = true
        }
        #expect(result == true)
        #expect(actionCalled == true)
    }

    @Test("recordAppear returns false on repeated appearance")
    func repeatedAppearance() {
        let manager = LifecycleManager()
        _ = manager.recordAppear(token: "view-1") {}
        nonisolated(unsafe) var secondCalled = false
        let result = manager.recordAppear(token: "view-1") {
            secondCalled = true
        }
        #expect(result == false)
        #expect(secondCalled == false)
    }

    @Test("hasAppeared returns false for unseen token")
    func hasNotAppeared() {
        let manager = LifecycleManager()
        #expect(manager.hasAppeared(token: "never-seen") == false)
    }

    @Test("hasAppeared returns true after recordAppear")
    func hasAppearedAfterRecord() {
        let manager = LifecycleManager()
        _ = manager.recordAppear(token: "view-1") {}
        #expect(manager.hasAppeared(token: "view-1") == true)
    }

    @Test("Multiple tokens are tracked independently")
    func independentTokens() {
        let manager = LifecycleManager()
        _ = manager.recordAppear(token: "a") {}
        _ = manager.recordAppear(token: "b") {}
        #expect(manager.hasAppeared(token: "a") == true)
        #expect(manager.hasAppeared(token: "b") == true)
        #expect(manager.hasAppeared(token: "c") == false)
    }

    @Test("reset clears all appeared tokens")
    func resetClears() {
        let manager = LifecycleManager()
        _ = manager.recordAppear(token: "view-1") {}
        _ = manager.recordAppear(token: "view-2") {}
        manager.reset()
        #expect(manager.hasAppeared(token: "view-1") == false)
        #expect(manager.hasAppeared(token: "view-2") == false)
    }
}

// MARK: - Render Pass Tests

@MainActor
@Suite("LifecycleManager Render Pass Tests")
struct LifecycleManagerRenderPassTests {

    @Test("beginRenderPass clears current render tokens")
    func beginRenderPassClears() {
        let manager = LifecycleManager()
        // Pass 1: view appears
        manager.beginRenderPass()
        _ = manager.recordAppear(token: "view-1") {}
        manager.endRenderPass() // sets visibleTokens = {"view-1"}

        // Pass 2: view does NOT appear
        manager.beginRenderPass() // clears currentRenderTokens
        manager.endRenderPass() // disappeared = {"view-1"}, removes from appearedTokens

        #expect(manager.hasAppeared(token: "view-1") == false)
    }

    @Test("endRenderPass triggers disappear for removed views")
    func disappearTriggered() {
        let manager = LifecycleManager()
        nonisolated(unsafe) var disappeared = false

        // Render pass 1: view appears
        manager.beginRenderPass()
        _ = manager.recordAppear(token: "view-1") {}
        manager.registerDisappear(token: "view-1") {
            disappeared = true
        }
        manager.endRenderPass()
        #expect(disappeared == false) // Still visible

        // Render pass 2: view is NOT rendered
        manager.beginRenderPass()
        // view-1 not recorded
        manager.endRenderPass()
        #expect(disappeared == true) // Now disappeared
    }

    @Test("endRenderPass does not trigger for views still visible")
    func noDisappearForVisible() {
        let manager = LifecycleManager()
        nonisolated(unsafe) var disappeared = false

        // Render pass 1
        manager.beginRenderPass()
        _ = manager.recordAppear(token: "view-1") {}
        manager.registerDisappear(token: "view-1") {
            disappeared = true
        }
        manager.endRenderPass()

        // Render pass 2: view still rendered
        manager.beginRenderPass()
        _ = manager.recordAppear(token: "view-1") {}
        manager.endRenderPass()
        #expect(disappeared == false) // Still visible, no disappear
    }

    @Test("View can reappear after disappearing")
    func reappearAfterDisappear() {
        let manager = LifecycleManager()
        nonisolated(unsafe) var appearCount = 0

        // Pass 1: appear
        manager.beginRenderPass()
        _ = manager.recordAppear(token: "view-1") { appearCount += 1 }
        manager.endRenderPass()
        #expect(appearCount == 1)

        // Pass 2: disappear (not rendered)
        manager.beginRenderPass()
        manager.endRenderPass()

        // Pass 3: reappear — action should fire again
        manager.beginRenderPass()
        _ = manager.recordAppear(token: "view-1") { appearCount += 1 }
        manager.endRenderPass()
        #expect(appearCount == 2)
    }
}

// MARK: - Disappear Callback Storage Tests

@MainActor
@Suite("LifecycleManager Disappear Callback Tests")
struct LifecycleManagerDisappearTests {

    @Test("registerDisappear stores callback")
    func registerStoresCallback() {
        let manager = LifecycleManager()
        nonisolated(unsafe) var called = false
        manager.registerDisappear(token: "view-1") {
            called = true
        }
        // Callback is stored but not called yet
        #expect(called == false)
    }

    @Test("unregisterDisappear removes callback")
    func unregisterRemoves() {
        let manager = LifecycleManager()
        nonisolated(unsafe) var called = false
        manager.registerDisappear(token: "view-1") {
            called = true
        }
        manager.unregisterDisappear(token: "view-1")

        // Simulate disappear — callback should NOT fire
        manager.beginRenderPass()
        _ = manager.recordAppear(token: "view-1") {}
        manager.endRenderPass()

        manager.beginRenderPass()
        // view-1 not rendered
        manager.endRenderPass()
        #expect(called == false) // Callback was unregistered
    }

    @Test("Repeated registration replaces one callback and unmount releases it")
    func repeatedRegistrationDoesNotGrow() {
        let manager = LifecycleManager()

        manager.beginRenderPass()
        _ = manager.recordAppear(token: "view-1") {}
        manager.registerDisappear(token: "view-1") {}
        manager.registerDisappear(token: "view-1") {}
        manager.endRenderPass()

        #expect(manager.disappearCallbackCount == 1)

        manager.beginRenderPass()
        manager.endRenderPass()

        #expect(manager.disappearCallbackCount == 0)
    }
}

// MARK: - Task Storage Tests

@MainActor
@Suite("LifecycleManager Task Tests")
struct LifecycleManagerTaskTests {

    @Test("Unchanged structural task stays mounted and ID changes replace it", .timeLimit(.minutes(1)))
    func structuralTaskIdentity() async {
        let manager = LifecycleManager()
        let identity = ViewIdentity(path: "Root/@task")
        let events = TraceRecorder<String>()
        let firstStarted = AsyncSignal()
        let firstRelease = AsyncSignal()
        let firstCompleted = AsyncSignal()
        let replacementStarted = AsyncSignal()

        manager.beginRenderPass()
        let started = manager.updateTask(identity: identity, id: 1, priority: .medium) {
            events.record("first-started")
            firstStarted.signal()
            await firstRelease.wait()
            events.record("first-cancelled:\(Task.isCancelled)")
            firstCompleted.signal()
        }
        manager.endRenderPass()
        await firstStarted.wait()

        manager.beginRenderPass()
        let preserved = manager.updateTask(identity: identity, id: 1, priority: .medium) {
            events.record("unexpected-restart")
        }
        manager.endRenderPass()

        #expect(started)
        #expect(preserved == false)
        #expect(manager.taskCount == 1)

        manager.beginRenderPass()
        let replaced = manager.updateTask(identity: identity, id: 2, priority: .medium) {
            events.record("replacement-started")
            replacementStarted.signal()
        }
        manager.endRenderPass()

        firstRelease.signal()
        await firstCompleted.wait()
        await replacementStarted.wait()

        #expect(replaced)
        #expect(events.snapshot().contains("unexpected-restart") == false)
        #expect(events.snapshot().contains("first-cancelled:true"))
        #expect(manager.taskCount == 1)
    }

    @Test("Unmount cancels and releases a structural task", .timeLimit(.minutes(1)))
    func structuralTaskUnmount() async {
        let manager = LifecycleManager()
        let identity = ViewIdentity(path: "Root/@task")
        let started = AsyncSignal()
        let release = AsyncSignal()
        let completed = AsyncSignal()
        let events = TraceRecorder<String>()

        manager.beginRenderPass()
        manager.updateTask(identity: identity, id: 1, priority: .medium) {
            started.signal()
            await release.wait()
            events.record("cancelled:\(Task.isCancelled)")
            completed.signal()
        }
        manager.endRenderPass()
        await started.wait()

        manager.beginRenderPass()
        manager.endRenderPass()
        release.signal()
        await completed.wait()

        #expect(events.snapshot() == ["cancelled:true"])
        #expect(manager.taskCount == 0)
    }

    @Test("Structural task preserves inherited MainActor isolation", .timeLimit(.minutes(1)))
    func structuralTaskActorIsolation() async {
        let manager = LifecycleManager()
        let identity = ViewIdentity(path: "Root/@task")
        let started = AsyncSignal()
        let state = MainActorTaskState()

        manager.beginRenderPass()
        manager.updateTask(identity: identity, id: 1, priority: .medium) {
            MainActor.preconditionIsolated()
            state.value = 42
            started.signal()
        }
        manager.endRenderPass()
        await started.wait()

        #expect(state.value == 42)
    }

    @Test("startTask runs its operation", .timeLimit(.minutes(1)))
    func startTask() async {
        let manager = LifecycleManager()
        let events = TraceRecorder<LifecycleTaskEvent>()
        let started = AsyncSignal()

        manager.startTask(token: "task-1", priority: .medium) {
            events.record(.started("task-1"))
            started.signal()
        }

        await started.wait()

        #expect(events.snapshot() == [.started("task-1")])
    }

    @Test("cancelTask cancels a running task", .timeLimit(.minutes(1)))
    func cancelTask() async {
        let manager = LifecycleManager()
        let events = TraceRecorder<LifecycleTaskEvent>()
        let started = AsyncSignal()
        let release = AsyncSignal()
        let completed = AsyncSignal()

        manager.startTask(token: "task-1", priority: .medium) {
            events.record(.started("task-1"))
            started.signal()
            await release.wait()
            events.record(.completed("task-1", wasCancelled: Task.isCancelled))
            completed.signal()
        }

        await started.wait()

        manager.cancelTask(token: "task-1")
        release.signal()
        await completed.wait()

        #expect(events.snapshot() == [
            .started("task-1"),
            .completed("task-1", wasCancelled: true)
        ])
    }

    @Test("startTask cancels the existing task and runs its replacement", .timeLimit(.minutes(1)))
    func replaceTask() async {
        let manager = LifecycleManager()
        let events = TraceRecorder<LifecycleTaskEvent>()
        let firstStarted = AsyncSignal()
        let firstRelease = AsyncSignal()
        let firstCompleted = AsyncSignal()
        let replacementStarted = AsyncSignal()

        manager.startTask(token: "task-1", priority: .medium) {
            events.record(.started("first"))
            firstStarted.signal()
            await firstRelease.wait()
            events.record(.completed("first", wasCancelled: Task.isCancelled))
            firstCompleted.signal()
        }

        await firstStarted.wait()

        manager.startTask(token: "task-1", priority: .medium) {
            events.record(.started("replacement"))
            replacementStarted.signal()
        }

        firstRelease.signal()
        await firstCompleted.wait()
        await replacementStarted.wait()

        let snapshot = events.snapshot()
        #expect(snapshot.count == 3)
        #expect(Set(snapshot) == [
            .started("first"),
            .completed("first", wasCancelled: true),
            .started("replacement")
        ])
    }

    @Test("reset cancels all running tasks", .timeLimit(.minutes(1)))
    func resetWithRunningTasks() async {
        let manager = LifecycleManager()
        let events = TraceRecorder<LifecycleTaskEvent>()
        let firstStarted = AsyncSignal()
        let firstRelease = AsyncSignal()
        let firstCompleted = AsyncSignal()
        let secondStarted = AsyncSignal()
        let secondRelease = AsyncSignal()
        let secondCompleted = AsyncSignal()

        manager.startTask(token: "task-1", priority: .medium) {
            events.record(.started("task-1"))
            firstStarted.signal()
            await firstRelease.wait()
            events.record(.completed("task-1", wasCancelled: Task.isCancelled))
            firstCompleted.signal()
        }
        manager.startTask(token: "task-2", priority: .medium) {
            events.record(.started("task-2"))
            secondStarted.signal()
            await secondRelease.wait()
            events.record(.completed("task-2", wasCancelled: Task.isCancelled))
            secondCompleted.signal()
        }

        await firstStarted.wait()
        await secondStarted.wait()

        manager.reset()
        firstRelease.signal()
        secondRelease.signal()
        await firstCompleted.wait()
        await secondCompleted.wait()

        let snapshot = events.snapshot()
        #expect(snapshot.count == 4)
        #expect(Set(snapshot) == [
            .started("task-1"),
            .completed("task-1", wasCancelled: true),
            .started("task-2"),
            .completed("task-2", wasCancelled: true)
        ])
    }
}

private enum LifecycleTaskEvent: Hashable, Sendable {
    case started(String)
    case completed(String, wasCancelled: Bool)
}

@MainActor
private final class MainActorTaskState {
    var value = 0
}
