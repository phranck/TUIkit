//  🖥️ TUIKit — Terminal UI Kit for Swift
//  SceneCompositionTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("Scene Composition")
struct SceneCompositionTests {

    /// Creates an isolated render context.
    private func testContext(width: Int = 30, height: Int = 5) -> RenderContext {
        RenderContext(
            availableWidth: width,
            availableHeight: height,
            tuiContext: TUIContext()
        )
    }

    // MARK: - Scene Modifiers

    @Test("The README palette-on-WindowGroup shape compiles and resolves")
    func paletteOnWindowGroupResolves() {
        let scene = WindowGroup {
            Text("content")
        }
        .palette(SystemPalette(.amber))

        var environment = EnvironmentValues()
        let resolved = SceneResolution.resolve(scene, applyingTo: &environment)

        #expect(resolved != nil)
        #expect(environment.palette.id == SystemPalette(.amber).id)
    }

    @Test("Nested scene modifiers compose outside-in")
    func nestedSceneModifiersCompose() {
        let scene = WindowGroup {
            Text("content")
        }
        .environment(\.pulsePhase, 0.75)
        .palette(SystemPalette(.amber))

        var environment = EnvironmentValues()
        _ = SceneResolution.resolve(scene, applyingTo: &environment)

        #expect(environment.pulsePhase == 0.75)
        #expect(environment.palette.id == SystemPalette(.amber).id)
    }

    @Test("The innermost scene value wins over outer duplicates")
    func innermostSceneValueWins() {
        let scene = WindowGroup {
            Text("content")
        }
        .environment(\.pulsePhase, 0.25)
        .environment(\.pulsePhase, 0.99)

        var environment = EnvironmentValues()
        _ = SceneResolution.resolve(scene, applyingTo: &environment)

        #expect(environment.pulsePhase == 0.25)
    }

    @Test("A resolved scene still renders its content")
    func resolvedSceneRenders() {
        let scene = WindowGroup {
            Text("rendered")
        }
        .palette(SystemPalette(.amber))

        var environment = EnvironmentValues()
        let resolved = SceneResolution.resolve(scene, applyingTo: &environment)
        let buffer = resolved?.renderScene(context: testContext())

        #expect(buffer?.lines.contains { $0.contains("rendered") } == true)
    }

    // MARK: - Scene Phase

    @Test("The environment exposes an active scene phase by default")
    func scenePhaseDefaultsToActive() {
        let environment = EnvironmentValues()

        #expect(environment.scenePhase == .active)
    }

    @Test("Scene phases order background below active")
    func scenePhaseOrdering() {
        #expect(ScenePhase.background < ScenePhase.inactive)
        #expect(ScenePhase.inactive < ScenePhase.active)
    }
}
