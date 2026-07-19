//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ObservationTrackingTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Observation
import Testing

@testable import TUIkit

// MARK: - Test Observable

@Observable
private class TestModel {
    var count = 0
    var name = "test"

    init() {}
}

// MARK: - Tests

@MainActor
@Suite("Observation Tracking Tests")
struct ObservationTrackingTests {

    @Test("@Observable property change triggers render via withObservationTracking")
    func observationTriggersRender() {
        let model = TestModel()
        let appState = AppState()
        #expect(!appState.needsRender)

        withObservationTracking {
            _ = model.count
        } onChange: {
            appState.setNeedsRenderWithCacheClear()
        }

        model.count = 42
        #expect(appState.needsRender)
        #expect(appState.consumeNeedsCacheClear())

        appState.didRender()
    }

    @Test("Multiple @Observable properties tracked independently")
    func multiplePropertiesTracked() {
        let model = TestModel()
        let appState = AppState()

        // Track count property
        withObservationTracking {
            _ = model.count
        } onChange: {
            appState.setNeedsRenderWithCacheClear()
        }

        model.count = 10
        #expect(appState.needsRender)
        #expect(appState.consumeNeedsCacheClear())
        appState.didRender()

        // Track name property
        withObservationTracking {
            _ = model.name
        } onChange: {
            appState.setNeedsRenderWithCacheClear()
        }

        model.name = "changed"
        #expect(appState.needsRender)
        #expect(appState.consumeNeedsCacheClear())
        appState.didRender()
    }

    @Test("onChange fires only once per tracking registration")
    func onChangeFiresOnce() {
        let model = TestModel()
        let appState = AppState()

        withObservationTracking {
            _ = model.count
        } onChange: {
            appState.setNeedsRenderWithCacheClear()
        }

        model.count = 1
        #expect(appState.needsRender)
        appState.didRender()
        _ = appState.consumeNeedsCacheClear()

        // Second mutation without re-registering should NOT trigger
        model.count = 2
        #expect(!appState.needsRender)
    }

    @Test("Untracked property change does not trigger render")
    func untrackedPropertyNoRender() {
        let model = TestModel()
        let appState = AppState()

        // Only track count, not name
        withObservationTracking {
            _ = model.count
        } onChange: {
            appState.setNeedsRenderWithCacheClear()
        }

        // Changing name (untracked) should not trigger
        model.name = "changed"
        #expect(!appState.needsRender)

        appState.didRender()
    }
}
