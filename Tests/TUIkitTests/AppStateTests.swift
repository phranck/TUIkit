//
//  AppStateTests.swift
//  TUIkit
//
//  Tests for AppState: render flag management and observer notification.
//

import Testing

@testable import TUIkit

@Suite("AppState Tests", .serialized)
struct AppStateTests {

    /// Creates a fresh AppState instance to isolate tests from shared global state.
    private func isolatedAppState() -> AppState {
        let fresh = AppState()
        AppState.active = fresh
        return fresh
    }

    @Test("AppState initially does not need render")
    func initialState() {
        let appState = isolatedAppState()
        appState.didRender()
        #expect(appState.needsRender == false)
    }

    @Test("setNeedsRender marks state as dirty")
    func setNeedsRender() {
        let appState = isolatedAppState()
        appState.didRender()
        appState.setNeedsRender()
        #expect(appState.needsRender == true)
    }

    @Test("didRender resets needsRender flag")
    func didRenderResets() {
        let appState = isolatedAppState()
        appState.setNeedsRender()
        #expect(appState.needsRender == true)
        appState.didRender()
        #expect(appState.needsRender == false)
    }

    @Test("setNeedsRender notifies observers")
    func observerNotified() {
        let appState = isolatedAppState()
        nonisolated(unsafe) var notified = false
        appState.observe {
            notified = true
        }
        appState.setNeedsRender()
        #expect(notified == true)
        appState.clearObservers()
    }

    @Test("Multiple observers all get notified")
    func multipleObservers() {
        let appState = isolatedAppState()
        nonisolated(unsafe) var count = 0
        appState.observe { count += 1 }
        appState.observe { count += 1 }
        appState.observe { count += 1 }
        appState.setNeedsRender()
        #expect(count == 3)
        appState.clearObservers()
    }

    @Test("clearObservers removes all observers")
    func clearObservers() {
        let appState = isolatedAppState()
        nonisolated(unsafe) var notified = false
        appState.observe { notified = true }
        appState.clearObservers()
        appState.setNeedsRender()
        #expect(notified == false)
    }
}
