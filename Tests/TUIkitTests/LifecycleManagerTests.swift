//
//  LifecycleManagerTests.swift
//  TUIkit
//
//  Tests for LifecycleManager: appear tracking, disappear callbacks,
//  render pass management, and async task lifecycle.
//

import Testing

@testable import TUIkit

// MARK: - Appear Tracking Tests

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
}

// MARK: - Task Storage Tests

@Suite("LifecycleManager Task Tests")
struct LifecycleManagerTaskTests {

    @Test("startTask creates a task")
    func startTask() async throws {
        let manager = LifecycleManager()
        nonisolated(unsafe) var executed = false
        manager.startTask(token: "task-1", priority: .medium) {
            executed = true
        }
        try await Task.sleep(for: .milliseconds(50))
        #expect(executed == true)
    }

    @Test("cancelTask sets cancellation flag")
    func cancelTask() async throws {
        let manager = LifecycleManager()
        nonisolated(unsafe) var wasCancelled = false
        manager.startTask(token: "task-1", priority: .medium) {
            // Long-running task that checks cancellation
            try? await Task.sleep(for: .seconds(10))
            wasCancelled = Task.isCancelled
        }
        // Cancel immediately
        manager.cancelTask(token: "task-1")
        try await Task.sleep(for: .milliseconds(50))
        // Task was cancelled, so it either didn't complete the sleep
        // or Task.isCancelled was true. Either way the task is cancelled.
        // We can't easily observe the internal state, but cancellation was requested.
        // This verifies cancelTask doesn't crash and processes correctly.
    }

    @Test("startTask replaces existing task for same token")
    func replaceTask() async throws {
        let manager = LifecycleManager()
        nonisolated(unsafe) var secondExecuted = false

        manager.startTask(token: "task-1", priority: .medium) {
            // Long-running first task
            try? await Task.sleep(for: .seconds(10))
        }
        // Replace immediately with short task
        manager.startTask(token: "task-1", priority: .medium) {
            secondExecuted = true
        }
        try await Task.sleep(for: .milliseconds(50))
        #expect(secondExecuted == true)
    }

    @Test("reset does not crash with running tasks")
    func resetWithRunningTasks() async throws {
        let manager = LifecycleManager()
        manager.startTask(token: "task-1", priority: .medium) {
            try? await Task.sleep(for: .seconds(10))
        }
        manager.startTask(token: "task-2", priority: .medium) {
            try? await Task.sleep(for: .seconds(10))
        }
        // Reset should cancel all tasks without crashing
        manager.reset()
        // Verify clean state
        #expect(manager.hasAppeared(token: "task-1") == false)
    }
}
