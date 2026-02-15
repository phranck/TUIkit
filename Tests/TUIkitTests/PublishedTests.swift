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
        AppState.shared.didRender()
        _ = AppState.shared.consumeNeedsCacheClear()
        #expect(!AppState.shared.needsRender)

        withObservationTracking {
            _ = model.count
        } onChange: {
            AppState.shared.setNeedsRenderWithCacheClear()
        }

        model.count = 42
        #expect(AppState.shared.needsRender)
        #expect(AppState.shared.consumeNeedsCacheClear())

        AppState.shared.didRender()
    }

    @Test("Multiple @Observable properties tracked independently")
    func multiplePropertiesTracked() {
        let model = TestModel()
        AppState.shared.didRender()
        _ = AppState.shared.consumeNeedsCacheClear()

        // Track count property
        withObservationTracking {
            _ = model.count
        } onChange: {
            AppState.shared.setNeedsRenderWithCacheClear()
        }

        model.count = 10
        #expect(AppState.shared.needsRender)
        #expect(AppState.shared.consumeNeedsCacheClear())
        AppState.shared.didRender()

        // Track name property
        withObservationTracking {
            _ = model.name
        } onChange: {
            AppState.shared.setNeedsRenderWithCacheClear()
        }

        model.name = "changed"
        #expect(AppState.shared.needsRender)
        #expect(AppState.shared.consumeNeedsCacheClear())
        AppState.shared.didRender()
    }

    @Test("onChange fires only once per tracking registration")
    func onChangeFiresOnce() {
        let model = TestModel()
        AppState.shared.didRender()
        _ = AppState.shared.consumeNeedsCacheClear()

        withObservationTracking {
            _ = model.count
        } onChange: {
            AppState.shared.setNeedsRenderWithCacheClear()
        }

        model.count = 1
        #expect(AppState.shared.needsRender)
        AppState.shared.didRender()
        _ = AppState.shared.consumeNeedsCacheClear()

        // Second mutation without re-registering should NOT trigger
        model.count = 2
        #expect(!AppState.shared.needsRender)
    }

    @Test("Untracked property change does not trigger render")
    func untrackedPropertyNoRender() {
        let model = TestModel()
        AppState.shared.didRender()
        _ = AppState.shared.consumeNeedsCacheClear()

        // Only track count, not name
        withObservationTracking {
            _ = model.count
        } onChange: {
            AppState.shared.setNeedsRenderWithCacheClear()
        }

        // Changing name (untracked) should not trigger
        model.name = "changed"
        #expect(!AppState.shared.needsRender)

        AppState.shared.didRender()
    }
}
