//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AppStateTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@Suite("AppState Tests")
struct AppStateTests {

    @Test("AppState initially does not need render")
    func initialState() {
        let appState = AppState()
        #expect(appState.needsRender == false)
    }

    @Test("setNeedsRender marks state as dirty")
    func setNeedsRender() {
        let appState = AppState()
        appState.setNeedsRender()
        #expect(appState.needsRender == true)
    }

    @Test("didRender resets needsRender flag")
    func didRenderResets() {
        let appState = AppState()
        appState.setNeedsRender()
        #expect(appState.needsRender == true)
        appState.didRender()
        #expect(appState.needsRender == false)
    }

    @Test("setNeedsRender notifies observers")
    func observerNotified() {
        let appState = AppState()
        nonisolated(unsafe) var notified = false
        appState.observe {
            notified = true
        }
        appState.setNeedsRender()
        #expect(notified == true)
    }

    @Test("Multiple observers all get notified")
    func multipleObservers() {
        let appState = AppState()
        nonisolated(unsafe) var count = 0
        appState.observe { count += 1 }
        appState.observe { count += 1 }
        appState.observe { count += 1 }
        appState.setNeedsRender()
        #expect(count == 3)
    }

    @Test("clearObservers removes all observers")
    func clearObservers() {
        let appState = AppState()
        nonisolated(unsafe) var notified = false
        appState.observe { notified = true }
        appState.clearObservers()
        appState.setNeedsRender()
        #expect(notified == false)
    }
}
