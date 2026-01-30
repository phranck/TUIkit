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
        AppState.shared.didRender()
        #expect(AppState.shared.needsRender == false)
    }

    @Test("setNeedsRender marks state as dirty")
    func setNeedsRender() {
        AppState.shared.didRender()
        AppState.shared.setNeedsRender()
        #expect(AppState.shared.needsRender == true)
    }

    @Test("didRender resets needsRender flag")
    func didRenderResets() {
        AppState.shared.setNeedsRender()
        #expect(AppState.shared.needsRender == true)
        AppState.shared.didRender()
        #expect(AppState.shared.needsRender == false)
    }

    @Test("setNeedsRender notifies observers")
    func observerNotified() {
        nonisolated(unsafe) var notified = false
        AppState.shared.observe {
            notified = true
        }
        AppState.shared.setNeedsRender()
        #expect(notified == true)
        AppState.shared.clearObservers()
        AppState.shared.didRender()
    }

    @Test("Multiple observers all get notified")
    func multipleObservers() {
        nonisolated(unsafe) var count = 0
        AppState.shared.observe { count += 1 }
        AppState.shared.observe { count += 1 }
        AppState.shared.observe { count += 1 }
        AppState.shared.setNeedsRender()
        #expect(count == 3)
        AppState.shared.clearObservers()
        AppState.shared.didRender()
    }

    @Test("clearObservers removes all observers")
    func clearObservers() {
        nonisolated(unsafe) var notified = false
        AppState.shared.observe { notified = true }
        AppState.shared.clearObservers()
        AppState.shared.setNeedsRender()
        #expect(notified == false)
        AppState.shared.didRender()
    }
}
