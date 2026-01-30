//
//  AppStateTests.swift
//  TUIkit
//
//  Tests for AppState: render flag management and observer notification.
//

import Testing

@testable import TUIkit

@Suite("AppState Tests")
@MainActor
struct AppStateTests {

    @Test("AppState initially does not need render")
    func initialState() {
        AppState.active.didRender()
        #expect(AppState.active.needsRender == false)
    }

    @Test("setNeedsRender marks state as dirty")
    func setNeedsRender() {
        AppState.active.didRender()
        AppState.active.setNeedsRender()
        #expect(AppState.active.needsRender == true)
    }

    @Test("didRender resets needsRender flag")
    func didRenderResets() {
        AppState.active.setNeedsRender()
        #expect(AppState.active.needsRender == true)
        AppState.active.didRender()
        #expect(AppState.active.needsRender == false)
    }

    @Test("setNeedsRender notifies observers")
    func observerNotified() {
        nonisolated(unsafe) var notified = false
        AppState.active.observe {
            notified = true
        }
        AppState.active.setNeedsRender()
        #expect(notified == true)
        AppState.active.clearObservers()
        AppState.active.didRender()
    }

    @Test("Multiple observers all get notified")
    func multipleObservers() {
        nonisolated(unsafe) var count = 0
        AppState.active.observe { count += 1 }
        AppState.active.observe { count += 1 }
        AppState.active.observe { count += 1 }
        AppState.active.setNeedsRender()
        #expect(count == 3)
        AppState.active.clearObservers()
        AppState.active.didRender()
    }

    @Test("clearObservers removes all observers")
    func clearObservers() {
        nonisolated(unsafe) var notified = false
        AppState.active.observe { notified = true }
        AppState.active.clearObservers()
        AppState.active.setNeedsRender()
        #expect(notified == false)
        AppState.active.didRender()
    }
}
