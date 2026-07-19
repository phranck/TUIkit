//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewRendererTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("ViewRenderer Tests", .serialized)
struct ViewRendererTests {
    @Test("Standalone rendering supports composite views and property wrappers")
    func standaloneRenderingSupportsCompositeViewsAndPropertyWrappers() {
        let terminal = MockTerminal()
        terminal.size = (40, 6)
        let tuiContext = TUIContext()
        tuiContext.storageBackend.setValue("owned", forKey: "renderer-name")
        let renderer = ViewRenderer(terminal: terminal, tuiContext: tuiContext)

        renderer.render {
            RendererPropertyWrapperView()
        }

        #expect(terminal.outputContains("owned:7"))
        #expect(tuiContext.stateStorage.count == 1)
        #expect(terminal.isRawModeEnabled == false)
        #expect(terminal.isInAlternateScreen == false)
    }

    @Test("Standalone builder receives the runtime environment")
    func standaloneBuilderReceivesRuntimeEnvironment() {
        let terminal = MockTerminal()
        let tuiContext = TUIContext()
        tuiContext.localizationService.setLanguage(.german)
        let renderer = ViewRenderer(terminal: terminal, tuiContext: tuiContext)

        renderer.render {
            Text(localized: "button.cancel")
        }

        #expect(terminal.outputContains("Abbrechen"))
    }

    @Test("Two runtimes render alternately without sharing state or services")
    func twoRuntimesRenderAlternatelyWithoutSharingStateOrServices() {
        let firstTerminal = MockTerminal()
        let secondTerminal = MockTerminal()
        let firstContext = TUIContext()
        let secondContext = TUIContext()
        firstContext.localizationService.setLanguage(.german)
        secondContext.localizationService.setLanguage(.french)
        firstContext.storageBackend.setValue("first", forKey: "alternating-runtime-name")
        secondContext.storageBackend.setValue("second", forKey: "alternating-runtime-name")
        firstContext.notificationService.post("first notification")
        secondContext.notificationService.post("second notification")
        firstContext.paletteManager.cycleNext()
        firstContext.focusManager.register(MockFocusable(id: "first-focus"))

        let firstRenderer = ViewRenderer(terminal: firstTerminal, tuiContext: firstContext)
        let secondRenderer = ViewRenderer(terminal: secondTerminal, tuiContext: secondContext)

        firstRenderer.render { AlternatingRuntimeView() }
        secondRenderer.render { AlternatingRuntimeView() }

        #expect(firstTerminal.outputContains("first:0:Abbrechen"))
        #expect(secondTerminal.outputContains("second:0:Annuler"))
        #expect(firstContext.notificationService.activeEntries().map(\.message) == ["first notification"])
        #expect(secondContext.notificationService.activeEntries().map(\.message) == ["second notification"])
        #expect(firstContext.paletteManager.current.id != secondContext.paletteManager.current.id)
        #expect(firstContext.focusManager.currentFocusedID == "first-focus")
        #expect(secondContext.focusManager.currentFocusedID == nil)

        let stateKey = StateStorage.StateKey(
            identity: ViewIdentity(rootType: AlternatingRuntimeView.self),
            propertyIndex: 0
        )
        let firstState: StateBox<Int> = firstContext.stateStorage.storage(for: stateKey, default: -1)
        firstContext.appState.didRender()
        secondContext.appState.didRender()
        firstState.value = 9

        #expect(firstContext.appState.needsRender)
        #expect(secondContext.appState.needsRender == false)

        secondTerminal.reset()
        secondRenderer.render { AlternatingRuntimeView() }
        firstTerminal.reset()
        firstRenderer.render { AlternatingRuntimeView() }

        #expect(secondTerminal.outputContains("second:0:Annuler"))
        #expect(firstTerminal.outputContains("first:9:Abbrechen"))
        #expect(firstContext.renderCache.stats.subtreeClears == 1)
        #expect(secondContext.renderCache.stats.subtreeClears == 0)
    }

    @Test("App rendering accepts an injected terminal session")
    func appRenderingAcceptsInjectedTerminalSession() {
        let terminal = MockTerminal()
        terminal.size = (40, 6)
        let tuiContext = TUIContext()
        tuiContext.statusBar.showSystemItems = false
        tuiContext.storageBackend.setValue("owned", forKey: "renderer-name")
        let renderLoop = RenderLoop(
            app: RendererTestApp(),
            terminal: terminal,
            statusBar: tuiContext.statusBar,
            appHeader: tuiContext.appHeader,
            focusManager: tuiContext.focusManager,
            paletteManager: tuiContext.paletteManager,
            appearanceManager: tuiContext.appearanceManager,
            tuiContext: tuiContext
        )

        renderLoop.render()

        #expect(terminal.outputContains("owned:7"))
        #expect(terminal.isRawModeEnabled == false)
        #expect(terminal.isInAlternateScreen == false)
    }
}

private struct RendererPropertyWrapperView: View {
    @State private var value = 7
    @AppStorage("renderer-name") private var name = "fallback"

    var body: some View {
        VStack {
            Text("\(name):\(value)")
        }
    }
}

private struct AlternatingRuntimeView: View {
    @State private var value = 0
    @AppStorage("alternating-runtime-name") private var name = "fallback"
    @Environment(\.localizationService) private var localization

    var body: some View {
        Text("\(name):\(value):\(localization.string(for: LocalizationKey.Button.cancel))")
            .equatable()
    }
}

@MainActor
private struct RendererTestApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            RendererPropertyWrapperView()
        }
    }
}
